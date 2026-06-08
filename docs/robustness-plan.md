# Robustness Plan

Goal: make this module succeed on a consumer's first `terraform apply`, and prove
the resulting VPC actually routes egress traffic. Findings from the audit on
2026-05-01 against `feat/add-tflint-validation` (HEAD `927f801`).

What "robust" means here, since this is a reusable module (not a deployable
config):

1. **Fail fast at `plan`** with clear messages when consumer inputs are invalid.
2. **Fail loudly at `apply`** when GCP returns something unexpected (vs. silently
   producing a broken VPC).
3. **Verify at runtime** that egress actually works — a green apply only proves
   GCP accepted the API calls.

---

## P0 — Live bug (do first, separate commit)

### 0.1 Root wrapper doesn't forward the `use_existing` feature

The last feature added `use_existing`, `existing_vpc_name`, `existing_subnet_name`
to `terraform/variables.tf` (lines 99–115), but `main.tf` and `variables.tf` at
the repo root were never updated. Consumers of the documented root entry point
get `use_existing = false` regardless of what they pass — the feature is
unreachable.

**Fix:**

- Add the three variable declarations to root `variables.tf`.
- Forward them in the `module "vpc_module"` block in root `main.tf` (after
  line 34).

**Commit type:** `fix:` (patch bump via Release Please — this is a real
regression in the feature shipped on `master`).

---

## P1 — Pre-flight validation (catch failures at `plan`)

Currently only `flow_sampling` has a `validation` block. The most common
first-time consumer mistakes hit GCP at apply with opaque error messages
(`googleapi: Error 400: Invalid value`). Add validations to surface them at plan
time with actionable text.

### 1.1 Variable validations

In `terraform/variables.tf` (and mirror in root `variables.tf` where the
variable also lives at the root):

| Variable | Validation | Why |
|---|---|---|
| `vpc_name` | `can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", var.vpc_name))` | GCP rejects underscores/uppercase with an opaque 400. |
| `subnet_cidr` | `can(cidrhost(var.subnet_cidr, 0))` | Catches malformed CIDRs before plan tries to use them. |
| `region` | non-empty + present in a curated allow-list (or just non-empty) | Empty region produces a confusing data-source error. |
| `existing_vpc_name`, `existing_subnet_name` | non-empty when `var.use_existing == true` | Default `""` produces a 404 from the data source instead of "you forgot to set X". |
| `allow_ssh_from_cidrs` | each entry passes `can(cidrhost(x, 0))` | Mistyped CIDRs become firewall apply errors. |

### 1.2 Cross-variable invariant

A single validation on `use_existing` that asserts both `existing_*` are set
when it's true. (Terraform 1.9+ supports cross-variable validations via
`var.x` references inside another variable's `validation` block; we already
require `>= 1.6` in `terraform/versions.tf:2` — bump to `>= 1.9` if needed.)

### 1.3 `terraform plan` in CI, not just `validate`

`.github/workflows/pre-commit.yml` runs `terraform validate`. That's a syntax
checker. Add a job that runs `terraform plan` against a fixture
(`test/fixtures/plan-only/main.tf`) with `-var project_id=test-project`. Catches
schema mismatches and unresolved references that `validate` misses.

For provider auth in CI, two options:
- A read-only service account in a sandbox project (`roles/viewer` is enough
  for plan).
- Terraform 1.7+ `mock_provider` — no GCP calls at all. Cheaper but doesn't
  catch real schema drift.

**Recommendation:** start with `mock_provider` since this is a public module
and we don't want to require sandbox-project setup. Revisit if mocks miss real
issues.

### 1.4 Commit the provider lockfile

`terraform/.terraform.lock.hcl` should be checked in so all consumers (and CI)
resolve to the same provider versions. Currently absent — `~> 7.0` lets a
breaking 7.x minor land asymmetrically across consumers.

```bash
cd terraform && terraform init && git add .terraform.lock.hcl
```

---

## P2 — Apply-time correctness (fail loudly, not silently)

### 2.1 Replace `try()` with explicit ternaries in locals

`terraform/main.tf:35-45` uses `try(resource[0].x, data[0].x)` to toggle between
create-mode and adopt-mode. If both fail, `try()` returns `null` and downstream
firewall rules attach to a null network with a confusing error far from the
root cause.

Replace with:

```hcl
vpc_id = var.use_existing ? data.google_compute_network.existing[0].id : google_compute_network.main[0].id
```

Slightly more verbose but error attribution is clear: a missing existing VPC
fails at the data source, a failed create fails at the resource.

### 2.2 Add `postcondition` blocks

On `google_compute_router_nat.main` and `google_compute_subnetwork.main`,
assert post-apply that GCP returned what we asked for. Cheap insurance against
provider-side surprises:

```hcl
lifecycle {
  postcondition {
    condition     = self.nat_ip_allocate_option == "AUTO_ONLY"
    error_message = "NAT IP allocation mode unexpectedly changed."
  }
}
```

### 2.3 Reconsider the `allow_egress` rule

`terraform/main.tf:177-194` creates an EGRESS firewall rule allowing tcp/443,
tcp/80, udp/53 to `0.0.0.0/0`. GCP's *default* egress rule already permits all
egress — this rule is a no-op unless paired with a deny-all egress rule. Either
remove it (one less rule to reason about) or add the matching deny. Document
the choice either way.

### 2.4 `allow_internal` and secondary ranges

`terraform/main.tf:139` sets `source_ranges = [local.subnet_cidr]`. When
`use_existing = true` and the existing subnet has secondary ranges (common for
GKE pod/service ranges), pods on secondary ranges can't reach VMs on the
primary range. Either:

- Read `data.google_compute_subnetwork.existing[0].secondary_ip_range` and
  union into `source_ranges`, or
- Document this as a known limitation.

---

## P3 — Post-deployment verification (prove it works)

A green `terraform apply` proves GCP accepted the calls, not that egress
functions. Currently zero automated checks of the running infra.

### 3.1 GCP Connectivity Tests (lightest weight)

Add `google_network_management_connectivity_test` resources for expected
egress paths. They run as part of the apply, no VM needed, result becomes a
Terraform output. Recommended:

- subnet → `8.8.8.8:443` (validates NAT path)
- subnet → `metadata.google.internal:80` (validates internal DNS / private
  Google access)

Make them togglable via `var.enable_connectivity_tests` (default `true`).

### 3.2 Terratest harness (highest confidence)

Create `test/vpc_egress_test.go` using Terratest. Per-PR run:

1. `terraform apply` the `test/fixtures/basic` config in a sandbox project.
2. Spin up an `e2-micro` with no external IP in the new subnet.
3. SSH via IAP, `curl -sS https://www.google.com`, assert HTTP 200.
4. Hit an external echo service, assert source IP is in GCP's NAT IP range
   (not the VM's internal IP).
5. `terraform destroy`.

Cost: ~$0.05/run (a few VM-minutes). Requires:
- A sandbox GCP project + service account with `roles/compute.networkAdmin`,
  `roles/compute.instanceAdmin`, `roles/iap.tunnelResourceAccessor`.
- Workload Identity Federation for keyless auth from GitHub Actions.

### 3.3 Smoke-test fixture for the `use_existing` path

A second fixture (`test/fixtures/use_existing`) that:

1. Creates a VPC + subnet via raw resources (not the module).
2. Invokes the module with `use_existing = true`.
3. Asserts firewall rules attach to the pre-existing VPC.

This is the only way to catch regressions in the adopt-mode path
short of a full Terratest run.

---

## Anticipatable first-apply blockers

Document these in the README "Prerequisites" section so consumers hit them
before invoking the module, not during apply:

| Blocker | Mitigation |
|---|---|
| `compute.googleapis.com` not enabled | Already handled by `google_project_service.compute`. ✓ |
| Caller SA missing `roles/compute.networkAdmin` | Document exact role list. Optional: add a `data "google_project_iam_member"` data source as a soft check. |
| `subnet_cidr` overlaps existing subnet | Not detectable at plan. Document, and let live test catch it. |
| `vpc_name = "default"` collides with auto-created default network | Add to validation reject-list. |
| Org policy `constraints/compute.restrictVpcPeering` or egress restrictions | Document; surface as a README troubleshooting entry. |
| Org policy `constraints/compute.vmExternalIpAccess` blocks the postgres example | Refactor example to IAP-only, or document the policy requirement. |
| Cloud NAT regional quota (default 64/region) | Document; not preemptable in Terraform. |
| Provider version drift across consumers | Commit `.terraform.lock.hcl` (P1.4). |

---

## Examples directory cleanup

`examples/basic.tf` at the top level + `examples/with-postgres-example/` as a
directory is two incompatible patterns. The naked `basic.tf` can't be
`terraform init`'d on its own without being copied into a directory. Pick one:

- **Recommended:** move `basic.tf` into `examples/basic/main.tf` so both
  examples follow the same shape and can be tested individually.

---

## Execution order

> **As of 2026-05-01:** Items P2.1, P2.2, P2.3, P3.1, P3.3 completed in PR #11. P1.1-1.2, P1.3, P3.2 captured as issues #12, #13, #14.

1. **P0.1** — fix the `use_existing` forwarding bug. One commit, `fix:` type.
   Lands a patch release. ✅ (already done - root main.tf had it)
2. **P1.1 + P1.2** — variable validations. One commit, `feat:` type. Minor bump.
   ⚠️ Partial - cross-variable validation missing (**issue #12**)
3. **P1.4** — commit `.terraform.lock.hcl`. `chore:` (no release). ✅ (already done)
4. **P2.1** — replace `try()` with explicit ternaries. `refactor:` (no release,
   but verify diff doesn't change plan output). ✅ **Done (PR #11)**
5. **P3.1** — connectivity tests. `feat:`, gated behind a variable defaulting
   to true. ✅ **Done (PR #11)**
6. **P1.3** — CI plan job. `chore:` workflow change. (**issue #13**)
7. **P3.2** — Terratest harness. Larger effort; do last and on its own branch.
   (**issue #14**)
8. **P2.2** — add postcondition blocks. ✅ **Done (PR #11)**
9. **P2.3** — remove allow_egress rule. ✅ **Done (PR #11)**
10. **P2.4** — handle secondary ranges for use_existing. ❌ Not done
11. **P3.3** — use_existing test fixture. ✅ **Done (PR #11)**
12. **Examples cleanup** — move basic.tf into examples/ directory. ❌ Not done

Each step above is independently shippable — none depend on later steps.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a production-ready Terraform module for setting up VPC egress infrastructure on Google Cloud Platform. It creates a VPC network with subnets, Cloud Router, Cloud NAT for outbound internet access, and firewall rules.

## Module Structure

The module uses a **nested module pattern**:
- **Root module** (`main.tf`, `variables.tf`, `versions.tf` at repository root) - Entry point that wraps the nested module
- **Nested module** (`terraform/` subdirectory) - Contains the actual infrastructure resources

Both root and nested modules expose the same variables and outputs for flexibility in how the module is consumed.

## Common Commands

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate Terraform syntax
terraform validate

# Initialize Terraform (for the with-postgres example)
cd examples/with-postgres-example && terraform init

# Plan example (requires GCP credentials)
cd examples/with-postgres-example && terraform plan

# Lint terraform with tflint (catches provider schema issues)
cd terraform && tflint --init --config=../.tflint.hcl && tflint --config=../.tflint.hcl

# Run pre-commit hooks (includes fmt and validate)
pre-commit run --all-files
```

## Development Workflow

1. **Format code** before committing: `terraform fmt -recursive`
2. **Validate** after formatting: `terraform validate`
3. **Pre-commit hooks** run automatically on commit (defined in `.pre-commit-config.yaml`)

## Architecture

The module creates these GCP resources:
- `google_compute_network` - VPC with auto-create subnets disabled
- `google_compute_subnetwork` - Single subnet with optional flow logging
- `google_compute_router` - Regional router for NAT
- `google_compute_router_nat` - NAT gateway for outbound internet access
- `google_compute_firewall` - Four rules: internal, SSH, PostgreSQL, egress

Key configuration:
- NAT uses `AUTO_ONLY` IP allocation (GCP manages IPs)
- `ALL_SUBNETWORKS_ALL_IP_RANGES` gives every VM egress access
- Firewall rules are conditionally created based on `allow_ssh` and `allow_postgres` flags
- Set `use_existing = true` to attach to an existing VPC/subnet instead of creating new ones. Network/subnet/router/NAT resources get `count = 0` and data sources are used instead; firewall rules are still created against the existing network. The `locals` block in `terraform/main.tf` uses `try()` to read from whichever side (resource or data source) is active.

## Module Usage

Reference via git source:
```hcl
module "vpc_egress" {
  source = "git::https://github.com/DarojaAI/gcp-vpc-egress-terraform.git//terraform"

  project_id  = "my-project"
  region      = "us-central1"
  vpc_name    = "my-vpc"
  subnet_cidr = "10.0.0.0/24"
}
```

Or reference root module directly:
```hcl
module "vpc_egress" {
  source = "github.com/DarojaAI/gcp-vpc-egress-terraform"

  project_id  = "my-project"
  region      = "us-central1"
  vpc_name    = "my-vpc"
  subnet_cidr = "10.0.0.0/24"
}
```

## Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP Project ID | required |
| `region` | GCP region | "us-central1" |
| `vpc_name` | VPC network name | required |
| `subnet_name` | Subnet name suffix (full name: `{vpc_name}-{subnet_name}`) | "subnet" |
| `subnet_cidr` | Subnet CIDR block | "10.0.0.0/24" |
| `environment` | Environment name | "dev" |
| `enable_flow_logs` | Enable VPC flow logging | true |
| `allow_ssh` | Create SSH firewall rule | true |
| `allow_ssh_from_cidrs` | CIDR blocks allowed for SSH | `["0.0.0.0/0"]` |
| `allow_postgres` | Create PostgreSQL firewall rule | true |
| `postgres_port` | PostgreSQL port | 5432 |
| `log_config_enabled` | Enable NAT + flow log logging | true |
| `flow_sampling` | VPC flow sampling rate (0.0–1.0) | 0.5 |
| `use_existing` | Attach to existing VPC/subnet instead of creating | false |
| `existing_vpc_name` | Existing VPC name (required when `use_existing = true`) | "" |
| `existing_subnet_name` | Existing subnet name (required when `use_existing = true`) | "" |

## Outputs

The module exports `vpc_id`, `subnet_id`, `router_id`, `nat_name`, and `connection_info` for integration with other modules (PostgreSQL, Kubernetes, dbt, etc.).

## Gotchas

- **Default value divergence:** Root module defaults `enable_flow_logs`, `allow_ssh`, `allow_postgres`, `log_config_enabled` to `true`; the nested `terraform/` module defaults them to `false`. If you consume the nested module directly (`source = ".../terraform"`), set these explicitly — don't rely on the table above, which reflects root-module defaults.
- **`use_existing` must be a literal bool or plain variable:** Never set `use_existing` to another module's output (e.g., `use_existing = module.foo.enabled`). Terraform evaluates `count` on resources/data sources at plan time — if the value isn't statically known, all `[0]` index accesses become non-deterministic and can produce spurious changes or errors. Use a local bool variable or a literal `true`/`false`.
- **Provider configuration:** The root passes `providers = { google = google }` to the nested module so callers can use `count`, `for_each`, and `depends_on` on the module block. Don't add `provider` blocks inside `terraform/`.

## Release Process

This project uses **Release Please** for automated semantic versioning based on conventional commits.

### Conventional Commits

Use these commit types to trigger version bumps:

| Commit Type | Release Type | Example |
|-------------|--------------|---------|
| `fix:` | patch (1.0.1 → 1.0.2) | `fix: resolve SSH firewall rule not applying` |
| `feat:` | minor (1.0.1 → 1.1.0) | `feat: add support for multiple subnets` |
| `feat!:` or `BREAKING CHANGE:` | major (1.0.1 → 2.0.0) | `feat!: change variable name from vpc_cidr to subnet_cidr` |
| `docs:`, `chore:`, `refactor:` | no release | `docs: update README with new examples` |

### How It Works

1. **Push to main/master** → Release Please analyzes commits and creates a PR with version changes
2. **Merge the PR** → Release Please creates a `v{major}.{minor}.{patch}` tag
3. **Tag push** → GitHub Release is automatically created with changelog

### Check Current Version

```bash
cat VERSION
# or
git describe --tags --abbrev=0
```
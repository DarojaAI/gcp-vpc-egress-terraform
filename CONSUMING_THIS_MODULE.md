# Consuming gcp-vpc-egress-terraform

This guide documents how to integrate the gcp-vpc-egress-terraform module into your infrastructure as code.

## Module Overview

gcp-vpc-egress-terraform creates a VPC network with subnet configuration, Cloud NAT for egress, and optional Cloud Router setup for hybrid connectivity.

## Required Inputs

These inputs must be provided to use this module:

| Input | Type | Description | Example |
|-------|------|-------------|---------|
| `project_id` | string | GCP project ID | `my-project-123` |
| `region` | string | GCP region | `us-central1` |
| `environment` | string | Deployment environment (dev/staging/prod) | `dev` |
| `vpc_name` | string | VPC network name | `rag-vpc` |
| `subnet_name` | string | Subnet name | `rag-subnet` |
| `subnet_cidr` | string | Subnet CIDR range | `10.0.1.0/24` |

> **Note:** No `repo_prefix` input exists. Resource naming is derived from `vpc_name`/`subnet_name` (e.g. `{vpc_name}-subnet`, `router-{vpc_name}`) — see `variables.tf`. Earlier versions of this doc listed `repo_prefix`; it was removed in PR #24.

## Optional Inputs

These inputs have sensible defaults but can be customized:

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `enable_flow_logs` | bool | `false` | Enable VPC flow logging |
| `log_config_enabled` | bool | `false` | Enable flow-log `log_config` block |
| `flow_sampling` | number | `0.5` | Flow-log sampling rate (0–1) |
| `allow_ssh` | bool | `false` | Open SSH from `allow_ssh_from_cidrs` |
| `allow_postgres` | bool | `false` | Allow Postgres (`postgres_port`) within subnet |
| `use_existing` | bool | `false` | Adopt existing VPC/subnet instead of creating |
| `existing_vpc_name` | string | `""` | Required when `use_existing = true` |
| `existing_subnet_name` | string | `""` | Required when `use_existing = true` |
| `enable_connectivity_tests` | bool | `false` | Create test VM + connectivity tests |

> **Note:** `enable_cloud_router` and `nat_log_filter` were removed in PR #24 — they are not module inputs. A Cloud Router + Cloud NAT are always created in create-mode; NAT log filter is fixed at `ERRORS_ONLY` in `terraform/main.tf`.

## Critical Outputs to Re-export

When consuming this module, **always provide these outputs** to downstream modules:

### VPC and Subnet Information

```hcl
output "vpc_id" {
  description = "VPC network resource ID (full path for PostgreSQL module)"
  value       = module.vpc_egress.vpc_id
}

output "vpc_name" {
  description = "VPC network name (bare name for documentation/tagging)"
  value       = module.vpc_egress.vpc_name
}

output "subnet_id" {
  description = "Subnet resource ID (full path for PostgreSQL module)"
  value       = module.vpc_egress.subnet_id
}

output "subnet_name" {
  description = "Subnet bare name (for Cloud Run and dbt modules)"
  value       = module.vpc_egress.subnet_name
}

output "subnet_cidr" {
  description = "Subnet CIDR range (for validation in downstream modules)"
  value       = module.vpc_egress.subnet_cidr
}
```

## Critical Pattern: Resource IDs vs Bare Names

This is the **most common source of confusion** when consuming this module. Different downstream modules expect different formats.

### ✓ CORRECT Usage Examples

**For PostgreSQL module (expects resource IDs):**
```hcl
module "postgres" {
  network_id = module.vpc_egress.vpc_id      # full path: projects/PROJECT/global/networks/vpc-name
  subnet_id  = module.vpc_egress.subnet_id    # full path: projects/PROJECT/regions/REGION/subnetworks/subnet-name
  subnet_cidr = module.vpc_egress.subnet_cidr # CIDR range: 10.0.1.0/24
}
```

**For Cloud Run / dbt modules (expect bare names):**
```hcl
module "dbt" {
  network_id    = module.vpc_egress.vpc_name      # bare name: rag-vpc
  subnetwork_id = module.vpc_egress.subnet_name   # bare name: rag-subnet (NOT subnet_id)
}
```

### ❌ WRONG Usage Examples

**❌ Using bare names with PostgreSQL:**
```hcl
network_id = module.vpc_egress.vpc_name        # WRONG: PostgreSQL needs full path
subnet_id  = module.vpc_egress.subnet_name     # WRONG: PostgreSQL needs full path
```

**❌ Using resource IDs with Cloud Run/dbt:**
```hcl
network_id    = module.vpc_egress.vpc_id       # WRONG: Cloud Run needs bare name
subnetwork_id = module.vpc_egress.subnet_id    # WRONG: Cloud Run needs bare name
```

## Common Pitfalls

### ❌ Mistake 1: Confusing Resource IDs and Bare Names

**Problem:** Passing the wrong format to downstream modules causes silent VPC wiring failures.

**Solution:**
- PostgreSQL module: Use `vpc_id` and `subnet_id` (resource IDs)
- Cloud Run/dbt modules: Use `vpc_name` and `subnet_name` (bare names)

Always verify in the downstream module's documentation which format it expects.

### ❌ Mistake 2: Hardcoding Network Names

**Wrong:**
```hcl
network_name = "rag-vpc"  # Hardcoded - breaks if module changes
subnet_name  = "rag-subnet"
```

**Correct:**
```hcl
network_name = module.vpc_egress.vpc_name
subnet_name  = module.vpc_egress.subnet_name
```

**Why:** Network names are module outputs. Always reference them to ensure consistency if the module changes.

### ❌ Mistake 3: Assuming a static NAT gateway IP output

**Wrong:**
```hcl
output "nat_gateway_ip" {
  description = "Cloud NAT public IP for external egress"
  value       = module.vpc_egress.nat_gateway_ip
}
```
The module exposes **no** `nat_gateway_ip` output. NAT is created with `nat_ip_allocate_option = "AUTO_ONLY"` (see `terraform/main.tf`), so the public IPs are ephemeral and Google-managed — there is nothing to reference.

**Correct:**
```hcl
# NAT exists in create-mode; reference its name for debugging/tags.
output "nat_name" {
  description = "Cloud NAT name (null when adopting an existing VPC)"
  value       = module.vpc_egress.nat_name
}
```

**Why:** Services needing outbound egress should rely on the VPC's NAT (auto-allocated public IPs), not a fixed IP. If a stable egress IP is a hard requirement, that is a module contract change — open an issue, don't re-architect it in the consuming repo (the module owns the NAT).

### ❌ Mistake 4: Not Validating CIDR Ranges

**Wrong:**
```hcl
# Create multiple subnets without checking CIDR overlap
subnet_cidr = "10.0.1.0/24"  # Hardcoded - may overlap
```

**Correct:**
```hcl
# Validate CIDR ranges before module instantiation
# Document CIDR allocation scheme in root module
subnet_cidr = var.subnet_cidr  # Passed from root module with validation
```

**Why:** CIDR overlap breaks VPC peering and causes routing conflicts. The VPC module validates this; consuming repos must respect the allocation.

## Integration Example

See [rag-research-tool](https://github.com/DarojaAI/rag_research_tool/blob/main/deploy/terraform/main.tf) for a complete integration example showing:

- VPC module instantiation with required inputs
- Output re-exports for both resource IDs and bare names
- Consumption by PostgreSQL module (using resource IDs)
- Consumption by dbt/Cloud Run modules (using bare names)
- Documentation of CIDR allocation strategy

## Related Documentation

- [gcp-postgres-terraform](https://github.com/DarojaAI/gcp-postgres-terraform) — PostgreSQL module that consumes vpc_id and subnet_id
- [gcp-dbt-terraform](https://github.com/DarojaAI/gcp-dbt-terraform) — dbt Cloud Run job that consumes vpc_name and subnet_name
- [GCP VPC Documentation](https://cloud.google.com/vpc/docs/vpc) — Official GCP VPC networking guide

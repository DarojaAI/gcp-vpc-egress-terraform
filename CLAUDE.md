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

# Initialize Terraform (if needed for examples)
cd examples/basic && terraform init

# Plan example (requires GCP credentials)
cd examples/basic && terraform plan

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
| `subnet_cidr` | Subnet CIDR block | "10.0.0.0/24" |
| `environment` | Environment name | "dev" |
| `enable_flow_logs` | Enable VPC flow logging | true |
| `allow_ssh` | Create SSH firewall rule | true |
| `allow_postgres` | Create PostgreSQL firewall rule | true |

## Outputs

The module exports `vpc_id`, `subnet_id`, `router_id`, `nat_name`, and `connection_info` for integration with other modules (PostgreSQL, Kubernetes, dbt, etc.).
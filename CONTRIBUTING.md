# Contributing to gcp-vpc-egress-terraform

See [DarojaAI/.github/CONTRIBUTING.md](https://github.com/DarojaAI/.github/blob/main/CONTRIBUTING.md) for organization-wide guidelines.

## This Repo: VPC Egress on Google Cloud

This repository provides a reusable Terraform module for Google Cloud VPC egress configuration including:
- VPC network with custom routes
- Cloud NAT for outbound connectivity
- Cloud Router for traffic management

### Setup

```bash
# Install Terraform
terraform version  # Should be ≥1.5.0

# Install pre-commit hooks
pip install pre-commit
pre-commit install
```

### Module Usage

This is a **reusable module**. To use it in another project:

```hcl
module "vpc_egress" {
  source = "git::https://github.com/DarojaAI/gcp-vpc-egress-terraform.git//terraform?ref=v1.0.0"
  
  project_id = var.project_id
  region     = var.region
  # See terraform/variables.tf for all options
}

output "nat_ip" {
  value = module.vpc_egress.nat_ip
}
```

### Development

```bash
# Validate locally
terraform -chdir=terraform validate

# Format
terraform fmt -recursive terraform/

# Pre-commit check
pre-commit run --all-files
```

### Release Process

1. **Test changes** with dependent projects
2. **Bump version** in `package.json`
3. **Create PR** with test results
4. **Merge** → GitHub Actions auto-tags and releases

### Important

- **This is a module** — always test in a dependent project before releasing
- **No terraform state** should be committed here
- **Version tags** match release versions (e.g., v1.0.0)
- **Breaking changes** require MAJOR version bump

---

For questions, see [GOVERNANCE.md](https://github.com/DarojaAI/.github/blob/main/GOVERNANCE.md)

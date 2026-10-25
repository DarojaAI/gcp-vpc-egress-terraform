terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# Use_existing = false exercises the create-mode branch: VPC, subnet,
# router, NAT, firewalls, project-service enablement. Default values
# chosen to avoid hitting the optional resources (no SSH, no Postgres,
# no connectivity tests / test VM).
#
# NOTE: mock_provider lives in the sibling plan_only.tftest.hcl file —
# not here. Per Hashi docs (terraform.language/tests/mocking), mock
# providers are restricted to the `terraform test` language; raw
# `terraform plan` / `terraform validate` will reject blocks of type
# mock_provider.
provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpc_egress" {
  source = "../../../terraform"

  project_id  = var.project_id
  region      = var.region
  vpc_name    = "${var.prefix}-vpc"
  subnet_name = "subnet"
  subnet_cidr = "10.0.10.0/24"

  use_existing              = false
  existing_vpc_name         = ""
  existing_subnet_name      = ""
  enable_flow_logs          = false
  enable_connectivity_tests = false
}

# Sanity outputs: surface the resolved resource IDs so a future debugging
# session can grep the plan JSON / test state for these tokens without
# re-reading the module surface. Under mock_provider they render blank;
# that's expected — the assertion is on attribute-set existence, not on
# real GCP values.
output "rendered_vpc_id" {
  value = module.vpc_egress.vpc_id
}

output "rendered_subnet_cidr" {
  value = module.vpc_egress.subnet_cidr
}

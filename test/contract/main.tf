# Contract fixture for terraform test (#32).
#
# Thin wrapper around the module so run blocks can toggle use_existing
# without re-declaring the module block per test. The output + resource
# contract assertions live in contract.tftest.hcl; this file is the
# (near-empty) config under test.

terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpc_egress" {
  source = "../../terraform"

  project_id  = var.project_id
  region      = var.region
  vpc_name    = var.vpc_name
  subnet_name = var.subnet_name
  subnet_cidr = var.subnet_cidr

  use_existing         = var.use_existing
  existing_vpc_name    = var.existing_vpc_name
  existing_subnet_name = var.existing_subnet_name

  enable_flow_logs          = false
  enable_connectivity_tests = false
}

output "txt_vpc_id" {
  value = module.vpc_egress.vpc_id
}

output "txt_subnet_cidr" {
  value = module.vpc_egress.subnet_cidr
}
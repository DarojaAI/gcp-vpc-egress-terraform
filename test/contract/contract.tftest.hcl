# Contract regression coverage (issue #32).
#
# Backs the public contract of a *consumable* module. Every consumer
# (dev-nexus, rag_research_tool, postgres-terraform) depends on the
# output keys + precondition behavior; contract drift is silent across
# all of them, so this test is the load-bearing CI gate.
#
# .tftest.hcl allows only: provider/mock_provider/run/assert blocks —
# no locals/variable declarations. See
# https://developer.hashicorp.com/terraform/language/tests.

mock_provider "google" {}

# Use_existing = false — create-mode graph must resolve and preserve the
# public output contract.
run "use_existing_false_contract" {
  command = apply

  variables {
    project_id           = "test-project"
    region               = "us-central1"
    vpc_name             = "contract-vpc"
    subnet_name          = "subnet"
    subnet_cidr          = "10.0.50.0/24"
    use_existing         = false
    existing_vpc_name    = ""
    existing_subnet_name = ""
  }

  # Output-contract stability (acceptance criterion #1): every public
  # output the module documents must be present and non-null in
  # create-mode (router_id/router_name/nat_name/firewall_*_rule are all
  # populated here). A rename like vpc_id -> vpc_name_output trips this.
  assert {
    condition     = module.vpc_egress.vpc_id != null
    error_message = "vpc_id output must resolve in create-mode."
  }
  assert {
    condition     = module.vpc_egress.vpc_name != null
    error_message = "vpc_name output must resolve in create-mode."
  }
  assert {
    condition     = module.vpc_egress.subnet_id != null
    error_message = "subnet_id output must resolve in create-mode."
  }
  assert {
    condition     = module.vpc_egress.subnet_name != null
    error_message = "subnet_name output must resolve in create-mode."
  }
  assert {
    condition     = module.vpc_egress.subnet_cidr != null
    error_message = "subnet_cidr output must resolve in create-mode."
  }
  assert {
    condition     = module.vpc_egress.router_id != null
    error_message = "router_id output must resolve in create-mode (router is created)."
  }
  assert {
    condition     = module.vpc_egress.nat_name != null
    error_message = "nat_name output must resolve in create-mode (NAT is created)."
  }
  assert {
    condition     = module.vpc_egress.firewall_internal_rule != null
    error_message = "firewall_internal_rule output must resolve in create-mode."
  }
  assert {
    condition     = module.vpc_egress.use_existing == false
    error_message = "use_existing must propagate false."
  }
}

# Use_existing = true — adopt-mode. Outputs that depend on *created*
# resources (router / NAT) must be null; the network-derived outputs
# must still resolve off the adopted network.
#
# This guards the `local.router_id = use_existing ? null : ...` contract
# in terraform/main.tf.
run "use_existing_true_adopt_mode" {
  command = apply

  variables {
    project_id           = "test-project"
    region               = "us-central1"
    vpc_name             = "contract-vpc"
    subnet_name          = "subnet"
    subnet_cidr          = "10.0.50.0/24"
    use_existing         = true
    existing_vpc_name    = "pre-existing-vpc"
    existing_subnet_name = "pre-existing-subnet"
  }

  assert {
    condition     = module.vpc_egress.use_existing == true
    error_message = "use_existing must propagate to the module."
  }
  # Adopting an existing VPC must NOT fabricate a router/NAT.
  assert {
    condition     = module.vpc_egress.router_id == null
    error_message = "router_id must be null when adopting an existing VPC."
  }
  assert {
    condition     = module.vpc_egress.router_name == null
    error_message = "router_name must be null when adopting an existing VPC."
  }
  assert {
    condition     = module.vpc_egress.nat_name == null
    error_message = "nat_name must be null when adopting an existing VPC."
  }
}

# Precondition message contract (acceptance criterion #3) is NOT
# expressible in this test file, and is intentionally left out rather
# than faked.
#
# The #12 fix (commit a26a298) installs `lifecycle.precondition` blocks on
# the child-module data sources (data.google_compute_network.existing[0] /
# data.google_compute_subnetwork.existing[0]) in terraform/main.tf. Terraform
# test's `expect_failures` can ONLY address checkable objects in the ROOT
# scope of the config under test, and here those data sources live inside
# the child module — so `terraform test` rejects the reference and cannot
# assert the precondition fires.
#
# Covered instead by the `terraform-test-precondition` job in pre-commit.yml:
# a fixture plans with use_existing=true and empty existing_vpc_name, and the
# job asserts a NON-ZERO exit + the exact message string
# "existing_vpc_name must be set when use_existing = true." (grep on stderr).
# See the job definition for the exact invocation.

# Plan-only smoke test (issue #13).
#
# Asserts the module's create-mode graph resolves under a Terraform-1.7+
# mock_provider. Catches schema mismatches and unresolved references
# that `terraform validate` misses, without GCP credentials or network.
#
# Why mock_provider + terraform test, not terraform plan:
#   * mock_provider is restricted to the test language (it lives in
#     .tftest.hcl files, not in regular .tf config). There is no
#     equivalent for raw `terraform plan` in TF 1.7+.
#   * terraform test walks the same graph that plan walks — when the
#     graph compiles and resources resolve cleanly, both succeed; when
#     a missing required argument or renames an upstream provider
#     attribute, this test fails loudly. The schema coverage this PR
#     promises comes from the graph-walk, not from a real plan.
#
# Pattern matches the existing test/fixtures/use_existing suite where
# reasonable. The `terraform test` invocation over the use_existing
# fixture is unchanged; this fixture adds the create-mode companion.

mock_provider "google" {}

run "create_mode_graph_resolves" {
  # All inputs are module defaults; assertions exercise the produced
  # graph shape, not real GCP values. With mock_provider, computed
  # attributes render as zero values — the test covers structure, not
  # values.

  assert {
    # Subnet CIDR round-trips through locals — proves the variable
    # binding + the conditional data-source branch work.
    condition     = output.rendered_subnet_cidr == "10.0.10.0/24"
    error_message = "subnet CIDR did not round-trip through locals as expected."
  }

  assert {
    # VPC ID is non-null after plan resolution. With mock_provider it
    # is a placeholder string, but the resource-graph resolve fails
    # loudly if any required argument is missing or any reference is
    # unresolved — which is the schema-coverage this PR promises.
    condition     = output.rendered_vpc_id != null
    error_message = "vpc_id is null — graph failed to resolve under mock_provider."
  }
}

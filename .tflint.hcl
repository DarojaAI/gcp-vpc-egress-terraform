plugin "google" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

rule "google_compute_firewall_invalid_name" {
  enabled = true
}

rule "google_compute_network_invalid_name" {
  enabled = true
}

rule "google_compute_router_invalid_name" {
  enabled = true
}

# Disable rules that may conflict with our structure
disable = [
  "terraform_deprecated_interpolation",
  "terraform_unused_declarations",
]

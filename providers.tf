# =============================================================================
# Terraform Provider Configuration
# =============================================================================

# The google provider is configured by the calling module (the root module
# consuming this wrapper). This allows the module to be used with count,
# for_each, and depends_on meta-arguments.
#
# See: https://developer.hashicorp.com/terraform/language/modules/develop/providers

terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# Provider is configured by calling module - see terraform block above

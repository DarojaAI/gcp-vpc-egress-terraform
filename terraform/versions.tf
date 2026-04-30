terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# Provider is passed from root module via the 'providers' block in the module call.
# This allows the module to be used with count, for_each, and depends_on.

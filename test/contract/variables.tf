variable "project_id" {
  description = "GCP project ID (mock_provider ignores this in plan-only)"
  type        = string
  default     = "test-project"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
  default     = "contract-vpc"
}

variable "subnet_name" {
  description = "Subnet name suffix"
  type        = string
  default     = "subnet"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.0.50.0/24"
}

variable "use_existing" {
  description = "Adopt existing VPC/subnet instead of creating"
  type        = bool
  default     = false
}

variable "existing_vpc_name" {
  description = "Existing VPC name (use_existing=true)"
  type        = string
  default     = ""
}

variable "existing_subnet_name" {
  description = "Existing subnet name (use_existing=true)"
  type        = string
  default     = ""
}
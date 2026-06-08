# =============================================================================
# Variables for GCP VPC Egress Module
# =============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region (e.g., us-central1)"
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", var.vpc_name))
    error_message = "vpc_name must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and be 1-63 characters long."
  }
}

variable "subnet_name" {
  description = "Subnet name suffix (full name: {vpc_name}-{subnet_name})"
  type        = string
  default     = "subnet"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block (e.g., 10.0.0.0/24)"
  type        = string
  default     = "10.0.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid CIDR block."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod, eai, etc.)"
  type        = string
  default     = "dev"
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logging"
  type        = bool
  default     = false
}

variable "allow_ssh" {
  description = "Allow SSH access from anywhere"
  type        = bool
  default     = false
}

variable "allow_ssh_from_cidrs" {
  description = "CIDR blocks allowed for SSH (if not allowing from anywhere)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.allow_ssh_from_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Each entry in allow_ssh_from_cidrs must be a valid CIDR block."
  }
}

variable "allow_postgres" {
  description = "Allow PostgreSQL access within subnet"
  type        = bool
  default     = false
}

variable "postgres_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    module     = "gcp-vpc-egress-terraform"
    managed_by = "terraform"
  }
}

variable "log_config_enabled" {
  description = "Enable logging for flow logs"
  type        = bool
  default     = false
}

variable "flow_sampling" {
  description = "VPC flow sampling rate (0.0 to 1.0)"
  type        = number
  default     = 0.5

  validation {
    condition     = var.flow_sampling >= 0 && var.flow_sampling <= 1
    error_message = "flow_sampling must be between 0 and 1"
  }
}

# =============================================================================
# Existing VPC / Subnet Configuration
# =============================================================================

variable "use_existing" {
  description = "Use existing VPC and subnet instead of creating new ones"
  type        = bool
  default     = false
}

variable "existing_vpc_name" {
  description = "Name of existing VPC network (required when use_existing is true)"
  type        = string
  default     = ""
}

variable "existing_subnet_name" {
  description = "Name of existing subnet (required when use_existing is true)"
  type        = string
  default     = ""
}

variable "enable_connectivity_tests" {
  description = "Enable GCP connectivity tests to verify egress paths (creates test VM)"
  type        = bool
  default     = false
}

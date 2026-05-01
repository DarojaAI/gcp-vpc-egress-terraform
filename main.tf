# =============================================================================
# GCP VPC Egress Terraform Module - Root Wrapper
#
# This module follows Terraform standard structure by providing the primary
# entrypoint at the repository root. It wraps and re-exports the nested
# module in the ./terraform directory.
#
# See: https://developer.hashicorp.com/terraform/language/modules/develop/structure
# =============================================================================

module "vpc_module" {
  source = "./terraform"

  # Pass provider configuration to nested module
  # This allows the module to be used with count, for_each, and depends_on
  providers = {
    google = google
  }

  project_id  = var.project_id
  region      = var.region
  vpc_name    = var.vpc_name
  subnet_name = var.subnet_name
  subnet_cidr = var.subnet_cidr
  environment = var.environment

  enable_flow_logs     = var.enable_flow_logs
  allow_ssh            = var.allow_ssh
  allow_ssh_from_cidrs = var.allow_ssh_from_cidrs
  allow_postgres       = var.allow_postgres
  postgres_port        = var.postgres_port
  tags                 = var.tags
  log_config_enabled   = var.log_config_enabled
  flow_sampling        = var.flow_sampling

  use_existing         = var.use_existing
  existing_vpc_name    = var.existing_vpc_name
  existing_subnet_name = var.existing_subnet_name

  enable_connectivity_tests = var.enable_connectivity_tests
}

# =============================================================================
# Re-export all outputs from nested module
# =============================================================================

output "vpc_id" {
  description = "VPC network ID"
  value       = module.vpc_module.vpc_id
}

output "vpc_name" {
  description = "VPC network name"
  value       = module.vpc_module.vpc_name
}

output "vpc_self_link" {
  description = "VPC network self link"
  value       = module.vpc_module.vpc_self_link
}

output "subnet_id" {
  description = "Subnet ID"
  value       = module.vpc_module.subnet_id
}

output "subnet_name" {
  description = "Subnet name"
  value       = module.vpc_module.subnet_name
}

output "subnet_cidr" {
  description = "Subnet CIDR block"
  value       = module.vpc_module.subnet_cidr
}

output "subnet_self_link" {
  description = "Subnet self link"
  value       = module.vpc_module.subnet_self_link
}

output "subnet_gateway_address" {
  description = "Subnet gateway address"
  value       = module.vpc_module.subnet_gateway_address
}

output "router_id" {
  description = "Cloud Router ID"
  value       = module.vpc_module.router_id
}

output "router_name" {
  description = "Cloud Router name"
  value       = module.vpc_module.router_name
}

output "firewall_postgres_rule" {
  description = "Firewall rule for PostgreSQL"
  value       = module.vpc_module.firewall_postgres_rule
}

output "firewall_ssh_rule" {
  description = "Firewall rule for SSH"
  value       = module.vpc_module.firewall_ssh_rule
}

output "firewall_internal_rule" {
  description = "Firewall rule for internal traffic"
  value       = module.vpc_module.firewall_internal_rule
}

output "firewall_egress_rule" {
  description = "Firewall rule for egress"
  value       = module.vpc_module.firewall_egress_rule
}

output "nat_name" {
  description = "Cloud NAT gateway name"
  value       = module.vpc_module.nat_name
}

output "connection_info" {
  description = "Connection information"
  value       = module.vpc_module.connection_info
}
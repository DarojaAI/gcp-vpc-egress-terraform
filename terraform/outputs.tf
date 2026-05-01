# =============================================================================
# Outputs - VPC Egress Module
# =============================================================================

output "vpc_id" {
  description = "VPC network ID"
  value       = local.vpc_id
}

output "vpc_name" {
  description = "VPC network name"
  value       = local.vpc_name
}

output "vpc_self_link" {
  description = "VPC network self link"
  value       = local.vpc_self_link
}

output "subnet_id" {
  description = "Subnet ID"
  value       = local.subnet_id
}

output "subnet_name" {
  description = "Subnet name"
  value       = local.subnet_name
}

output "subnet_cidr" {
  description = "Subnet CIDR block"
  value       = local.subnet_cidr
}

output "subnet_self_link" {
  description = "Subnet self link"
  value       = local.subnet_self_link
}

output "subnet_gateway_address" {
  description = "Subnet gateway address"
  value       = local.subnet_gateway
}

output "router_id" {
  description = "Cloud Router ID (null when using existing VPC)"
  value       = var.use_existing ? null : google_compute_router.main[0].id
}

output "router_name" {
  description = "Cloud Router name (null when using existing VPC)"
  value       = var.use_existing ? null : google_compute_router.main[0].name
}

output "nat_name" {
  description = "Cloud NAT name (null when using existing VPC)"
  value       = var.use_existing ? null : google_compute_router_nat.main[0].name
}

output "firewall_internal_rule" {
  description = "Internal firewall rule name"
  value       = google_compute_firewall.allow_internal.name
}

output "firewall_ssh_rule" {
  description = "SSH firewall rule name (if enabled)"
  value       = var.allow_ssh ? google_compute_firewall.allow_ssh[0].name : null
}

output "firewall_postgres_rule" {
  description = "PostgreSQL firewall rule name (if enabled)"
  value       = var.allow_postgres ? google_compute_firewall.allow_postgres[0].name : null
}


output "use_existing" {
  description = "Whether using existing VPC/subnet"
  value       = var.use_existing
}

output "connection_info" {
  description = "Connection information for referencing in other modules"
  value = {
    vpc_id       = local.vpc_id
    subnet_id    = local.subnet_id
    subnet_cidr  = local.subnet_cidr
    router_id    = var.use_existing ? null : google_compute_router.main[0].id
    router_name  = var.use_existing ? null : google_compute_router.main[0].name
    nat_name     = var.use_existing ? null : google_compute_router_nat.main[0].name
    region       = var.region
    project_id   = var.project_id
    use_existing = var.use_existing
  }
}

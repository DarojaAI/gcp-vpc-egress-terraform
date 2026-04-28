# =============================================================================
# Outputs - VPC Egress Module
# =============================================================================

output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.main.id
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.main.name
}

output "vpc_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.main.self_link
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.main.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.main.name
}

output "subnet_cidr" {
  description = "Subnet CIDR block"
  value       = google_compute_subnetwork.main.ip_cidr_range
}

output "subnet_self_link" {
  description = "Subnet self link"
  value       = google_compute_subnetwork.main.self_link
}

output "subnet_gateway_address" {
  description = "Subnet gateway address"
  value       = google_compute_subnetwork.main.gateway_address
}

output "router_id" {
  description = "Cloud Router ID"
  value       = google_compute_router.main.id
}

output "router_name" {
  description = "Cloud Router name"
  value       = google_compute_router.main.name
}

output "nat_name" {
  description = "Cloud NAT name"
  value       = google_compute_router_nat.main.name
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

output "firewall_egress_rule" {
  description = "Egress firewall rule name"
  value       = google_compute_firewall.allow_egress.name
}

output "connection_info" {
  description = "Connection information for referencing in other modules"
  value = {
    vpc_id         = google_compute_network.main.id
    subnet_id      = google_compute_subnetwork.main.id
    subnet_cidr    = google_compute_subnetwork.main.ip_cidr_range
    router_id      = google_compute_router.main.id
    router_name    = google_compute_router.main.name
    nat_name       = google_compute_router_nat.main.name
    region         = var.region
    project_id     = var.project_id
  }
}

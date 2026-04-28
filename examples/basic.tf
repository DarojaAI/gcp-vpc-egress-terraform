# =============================================================================
# Example: Basic VPC Egress Setup
# =============================================================================

module "vpc_egress" {
  source = "../terraform"

  project_id  = "my-project-id"
  region      = "us-central1"
  vpc_name    = "my-vpc"
  subnet_name = "main"
  subnet_cidr = "10.0.0.0/24"
  environment = "dev"

  allow_ssh      = true
  allow_postgres = true
}

output "vpc_id" {
  value = module.vpc_egress.vpc_id
}

output "subnet_id" {
  value = module.vpc_egress.subnet_id
}

output "router_name" {
  value = module.vpc_egress.router_name
}

output "nat_name" {
  value = module.vpc_egress.nat_name
}

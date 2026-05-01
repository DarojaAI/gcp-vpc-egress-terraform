terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Create pre-existing VPC (not managed by module)
resource "google_compute_network" "preexisting" {
  name                    = "${var.prefix}-preexisting-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "preexisting" {
  name          = "${var.prefix}-preexisting-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.preexisting.id
}

# Invoke module with use_existing = true
module "vpc_egress" {
  source = "../../../terraform"

  project_id  = var.project_id
  region      = var.region
  vpc_name    = "${var.prefix}-vpc"
  subnet_name = "subnet"
  subnet_cidr = var.subnet_cidr

  use_existing         = true
  existing_vpc_name    = google_compute_network.preexisting.name
  existing_subnet_name = google_compute_subnetwork.preexisting.name

  enable_flow_logs     = false
  allow_ssh            = true
  allow_ssh_from_cidrs = ["10.0.0.0/8"]
  allow_postgres       = true
}
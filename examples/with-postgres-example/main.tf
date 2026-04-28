# =============================================================================
# Example: VPC Egress with PostgreSQL VM Integration
# =============================================================================

# VPC with egress
module "vpc_egress" {
  source = "../../terraform"

  project_id  = var.project_id
  region      = var.region
  vpc_name    = "rag-research-vpc"
  subnet_name = "postgres"
  subnet_cidr = "10.1.0.0/24"
  environment = "production"

  allow_ssh            = true
  allow_ssh_from_cidrs = ["YOUR_IP/32"] # Restrict SSH to your IP
  allow_postgres       = true
  postgres_port        = 5432
}

# PostgreSQL VM using the VPC
resource "google_compute_instance" "postgres" {
  name         = "postgres-vm"
  machine_type = "e2-medium"
  zone         = "${var.region}-b"

  tags = ["ssh", "postgres"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = "20"
    }
  }

  network_interface {
    subnetwork = module.vpc_egress.subnet_id
    access_config {
      nat_ip = google_compute_address.postgres_external.address
    }
  }

  # Startup script uses NAT to download packages
  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      set -euo pipefail
      apt-get update
      apt-get install -y postgresql-16 postgresql-contrib-16 postgresql-16-pgvector
      systemctl start postgresql
      systemctl enable postgresql
    EOT
  }
}

# External IP for SSH access
resource "google_compute_address" "postgres_external" {
  name         = "postgres-external-ip"
  address_type = "EXTERNAL"
  region       = var.region
}

output "vpc_id" {
  value = module.vpc_egress.vpc_id
}

output "postgres_vm_ssh" {
  value = "gcloud compute ssh postgres-vm --zone ${var.region}-b"
}

output "postgres_internal_ip" {
  value = google_compute_instance.postgres.network_interface[0].network_ip
}

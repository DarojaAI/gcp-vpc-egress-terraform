# =============================================================================
# GCP VPC Egress Module - Main Infrastructure
# =============================================================================

# ============================================
# Enable Required APIs
# ============================================

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# ============================================
# Data Sources for Existing VPC/Subnet
# ============================================

data "google_compute_network" "existing" {
  count   = var.use_existing ? 1 : 0
  name    = var.existing_vpc_name
  project = var.project_id
}

data "google_compute_subnetwork" "existing" {
  count   = var.use_existing ? 1 : 0
  name    = var.existing_subnet_name
  region  = var.region
  project = var.project_id
}

# ============================================
# Local Values for VPC/Subnet
# ============================================

locals {
  # Explicitly toggle between create-mode and adopt-mode
  # This gives clear error attribution: data source fails at data source, resource fails at resource
  vpc_id           = var.use_existing ? data.google_compute_network.existing[0].id : google_compute_network.main[0].id
  vpc_name         = var.use_existing ? data.google_compute_network.existing[0].name : google_compute_network.main[0].name
  vpc_self_link    = var.use_existing ? data.google_compute_network.existing[0].self_link : google_compute_network.main[0].self_link
  subnet_id        = var.use_existing ? data.google_compute_subnetwork.existing[0].id : google_compute_subnetwork.main[0].id
  subnet_name      = var.use_existing ? data.google_compute_subnetwork.existing[0].name : google_compute_subnetwork.main[0].name
  subnet_cidr      = var.use_existing ? data.google_compute_subnetwork.existing[0].ip_cidr_range : google_compute_subnetwork.main[0].ip_cidr_range
  subnet_self_link = var.use_existing ? data.google_compute_subnetwork.existing[0].self_link : google_compute_subnetwork.main[0].self_link
  subnet_gateway   = var.use_existing ? data.google_compute_subnetwork.existing[0].gateway_address : google_compute_subnetwork.main[0].gateway_address
}

# ============================================
# VPC Network (created only when not using existing)
# ============================================

resource "google_compute_network" "main" {
  count                   = var.use_existing ? 0 : 1
  name                    = var.vpc_name
  auto_create_subnetworks = false
  depends_on              = [google_project_service.compute]
}

# ============================================
# Subnet with Flow Logging (created only when not using existing)
# ============================================

resource "google_compute_subnetwork" "main" {
  count         = var.use_existing ? 0 : 1
  name          = "${var.vpc_name}-${var.subnet_name}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main[0].id

  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.log_config_enabled ? [1] : []
    content {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = var.flow_sampling
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }

  lifecycle {
    postcondition {
      condition     = self.private_ip_google_access == true
      error_message = "private_ip_google_access must remain enabled for Private Google Access."
    }
  }
}

# ============================================
# Cloud Router for NAT (created only when not using existing)
# ============================================

resource "google_compute_router" "main" {
  count   = var.use_existing ? 0 : 1
  name    = "router-${var.vpc_name}"
  region  = var.region
  network = local.vpc_id

  depends_on = [google_project_service.compute]
}

# ============================================
# Cloud NAT - Outbound Internet Access (created only when not using existing)
# ============================================

resource "google_compute_router_nat" "main" {
  count                              = var.use_existing ? 0 : 1
  name                               = "nat-${var.vpc_name}"
  router                             = google_compute_router.main[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = var.log_config_enabled
    filter = "ERRORS_ONLY"
  }

  lifecycle {
    postcondition {
      condition     = self.nat_ip_allocate_option == "AUTO_ONLY"
      error_message = "NAT IP allocation mode unexpectedly changed from AUTO_ONLY."
    }
  }

  depends_on = [google_compute_router.main]
}

# ============================================
# Firewall Rules
# ============================================

# Allow internal traffic within the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = local.vpc_name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [local.subnet_cidr]
}

# Allow SSH access
resource "google_compute_firewall" "allow_ssh" {
  count   = var.allow_ssh ? 1 : 0
  name    = "${var.vpc_name}-allow-ssh"
  network = local.vpc_name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allow_ssh_from_cidrs
  target_tags   = ["ssh"]
}

# Allow PostgreSQL access within subnet
resource "google_compute_firewall" "allow_postgres" {
  count   = var.allow_postgres ? 1 : 0
  name    = "${var.vpc_name}-allow-postgres"
  network = local.vpc_name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [var.postgres_port]
  }

  source_ranges = [local.subnet_cidr]
  target_tags   = ["postgres"]
}

# ============================================
# Connectivity Tests (verify egress works)
# ============================================

# Test NAT egress path: subnet -> 8.8.8.8:443
resource "google_network_management_connectivity_test" "nat_egress" {
  count = var.enable_connectivity_tests && !var.use_existing ? 1 : 0

  name = "${var.vpc_name}-test-nat-egress"

  source {
    instance = google_compute_instance.test_vm[0].id
  }

  destination {
    ip_address = "8.8.8.8"
    port       = 443
  }

  protocol = "TCP"
}

# Test Private Google Access: subnet -> metadata.google.internal
resource "google_network_management_connectivity_test" "private_google_access" {
  count = var.enable_connectivity_tests && !var.use_existing ? 1 : 0

  name = "${var.vpc_name}-test-private-google-access"

  source {
    instance = google_compute_instance.test_vm[0].id
  }

  destination {
    ip_address = "metadata.google.internal"
    port       = 80
  }

  protocol = "TCP"
}

# Minimal test VM (no external IP) in the subnet to run connectivity tests
resource "google_compute_instance" "test_vm" {
  count = var.enable_connectivity_tests && !var.use_existing ? 1 : 0

  name         = "${var.vpc_name}-test-vm"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main[0].id
    # No external IP - tests NAT functionality
  }

  tags = ["ssh", "postgres"]

  metadata = {
    enable-oslogin = "true"
  }

  depends_on = [google_compute_router_nat.main]
}


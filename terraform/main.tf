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
# VPC Network
# ============================================

resource "google_compute_network" "main" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  depends_on              = [google_project_service.compute]
}

# ============================================
# Subnet with Flow Logging
# ============================================

resource "google_compute_subnetwork" "main" {
  name          = "${var.vpc_name}-${var.subnet_name}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  private_ip_google_access = true

  dynamic "log_config" {
    for_each = var.log_config_enabled ? [1] : []
    content {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = var.flow_sampling
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }

  labels = var.tags
}

# ============================================
# Cloud Router for NAT
# ============================================

resource "google_compute_router" "main" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = google_compute_network.main.id

  depends_on = [google_project_service.compute]
}

# ============================================
# Cloud NAT - Outbound Internet Access
# ============================================

resource "google_compute_router_nat" "main" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = var.log_config_enabled
    filter = "ERRORS_ONLY"
  }

  depends_on = [google_compute_router.main]
}

# ============================================
# Firewall Rules
# ============================================

# Allow internal traffic within the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.main.name

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

  source_ranges = [var.subnet_cidr]
}

# Allow SSH access
resource "google_compute_firewall" "allow_ssh" {
  count   = var.allow_ssh ? 1 : 0
  name    = "${var.vpc_name}-allow-ssh"
  network = google_compute_network.main.name

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
  network = google_compute_network.main.name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [var.postgres_port]
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["postgres"]
}

# Allow outbound egress traffic (https, http, dns)
resource "google_compute_firewall" "allow_egress" {
  name    = "${var.vpc_name}-allow-egress"
  network = google_compute_network.main.name

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443", "80"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  destination_ranges = ["0.0.0.0/0"]
}

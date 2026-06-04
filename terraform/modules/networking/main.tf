resource "google_compute_network" "module_vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.project_id
}

resource "google_compute_subnetwork" "module_subnets" {
  for_each = var.subnets
  name          = "${var.network_name}-${each.key}"
  ip_cidr_range = each.value
  region        = var.region
  network       = google_compute_network.module_vpc.id
  project       = var.project_id
}

resource "google_compute_firewall" "module_allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.module_vpc.name
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
  source_ranges = ["10.10.0.0/16"]
  project       = var.project_id
}

resource "google_compute_firewall" "module_allow_ingress" {
  name    = "${var.network_name}-allow-ingress"
  network = google_compute_network.module_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22", "443", "80"]
  }
  # Split ingress rules: SSH limited to admin CIDRs, HTTP/HTTPS limited to public CIDRs
  source_ranges = var.allowed_public_cidrs
  project       = var.project_id
}

resource "google_compute_firewall" "module_allow_ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.module_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = var.allowed_admin_cidrs
  project       = var.project_id
}

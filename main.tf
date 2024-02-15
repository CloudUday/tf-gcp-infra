provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name          = "webapp"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.1.0/24"
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = "db"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.2.0/24"
}

resource "google_compute_route" "internet_access" {
  name            = "internet-access"
  network         = google_compute_network.vpc.id
  dest_range      = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}


resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  delete_default_routes_on_create = true
  
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name          = "${var.vpc_name}-webapp"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.webapp_subnet_cidr
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = "${var.vpc_name}-db"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.db_subnet_cidr 
}

resource "google_compute_route" "internet_access" {
  name             = "${var.vpc_name}-internet-access"
  network          = google_compute_network.vpc.id
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority = 1000
  depends_on = [google_compute_subnetwork.webapp_subnet] 
}

resource "google_compute_firewall" "allow_webapplication" {
  name    = "${var.vpc_name}-allow-webapplication"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = [var.app_port]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "deny_ssh" {
  name    = "${var.vpc_name}-deny-ssh"
  network = google_compute_network.vpc.id

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

#  start of private service access
resource "google_compute_global_address" "default" {
  provider     = google-beta
  project      = var.project_id
  name         = "${var.vpc_name}-psconnect-ip"
  address_type = "INTERNAL"
  purpose      = "VPC_PEERING"
  network      = google_compute_network.vpc.id
  prefix_length = 16
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta
  network  = google_compute_network.vpc.id
  service  = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.default.name]
}


# end of private service access

resource "google_compute_instance" "vm_instance" {
  name         = var.vm_name  
  zone         = var.vm_zone
  machine_type = var.vm_machine_type

  boot_disk {
    initialize_params {
      image = var.vm_image
      type  = var.vm_disk_type
      size  = var.vm_disk_size_gb
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.webapp_subnet.id

    access_config {
      // Assigns a public IP address
    }
  }
}

#  start of creating cloudsql instance 

resource "google_sql_database_instance" "cloudsql_instance" {
  provider = google-beta

  name             = "your-cloudsql-instance-healthapp" # Ensure this is unique
  region           = var.region
  database_version = "MYSQL_5_7" # Example, adjust as needed
  project          = var.project_id
  deletion_protection = false

  settings {
    tier = "db-f1-micro" # Adjust as needed, example tier

    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_global_address.default.network
      require_ssl = true # If you want to enforce SSL
    }

    disk_type = "PD_SSD"
    disk_size = 100
    disk_autoresize = true # Optional, based on your preference
    availability_type = "REGIONAL"

  }

  # This depends_on is crucial to ensure the network settings are in place before the instance is created
  depends_on = [google_service_networking_connection.private_vpc_connection]
}






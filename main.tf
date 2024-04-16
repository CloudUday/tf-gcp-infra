provider "google" {
  project = var.project_id
  region = var.region
}
data "google_compute_zones" "this" {
  region  = var.region
  project = var.project_id
}


resource "google_compute_network" "vpc" {
  name                          = var.vpc_name
  auto_create_subnetworks       = false
  delete_default_routes_on_create = true
  routing_mode                  = var.routing_mode
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name          = "${var.vpc_name}-webapp"
  ip_cidr_range = var.webapp_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = "${var.vpc_name}-db"
  ip_cidr_range = var.db_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_route" "webapp_route" {
  name            = "${var.vpc_name}-webapp-route"
  dest_range      = var.Destination_range
  network         = google_compute_network.vpc.id
  next_hop_gateway = "default-internet-gateway"
  priority        = var.priorityvalue

  depends_on = [
    google_compute_subnetwork.webapp_subnet
  ]
}

 resource "google_compute_firewall" "allow_web" {
  name      = "allow-loadb-to-virtualms"
  network   = google_compute_network.vpc.self_link
  direction = var.direction
 
  allow {
    protocol = var.protocol
    ports    =[var.app_port]
  }
 
 
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
 
}

resource "google_compute_firewall" "deny_ssh" {
  name    = "${var.vpc_name}-deny-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = var.protocol
    ports    = [var.ssh_port]
  }

  source_ranges = [var.source_ranges]
}


resource "google_compute_address" "static_ip" {
  name   = "vm-static-ip"
  region = var.region
}
resource "google_pubsub_topic" "verify_email" {
  name = "verify_email"
  message_retention_duration = "604800s" 
}

resource "google_pubsub_subscription" "verify_email_subscription" {
  name  = "verify_email_subscription"
  topic = google_pubsub_topic.verify_email.name
  ack_deadline_seconds = 20  
  push_config {
  push_endpoint = google_cloudfunctions2_function.verify_email_function.url
}
}

  
 

 
 
resource "google_cloudfunctions2_function" "verify_email_function" {
  depends_on  = [google_vpc_access_connector.vpc_connector , google_service_account.cloudfunction_service_account]
  name        = "verify-email-function"
  description = "Verification of Email"
  location = "us-east4"
 
  build_config {
    runtime = "nodejs20"
    entry_point = "sendVerificationEmail"
    source {
      storage_source {
        bucket = google_storage_bucket.serverless-bucket.name
        object = google_storage_bucket_object.serverless-archive.name
      }
    }
  }
 
      service_config {
    max_instance_count  = 3
    min_instance_count = 2
    available_memory    = "256Mi"
    available_cpu = 1
    timeout_seconds     = 540
    max_instance_request_concurrency = 1
    environment_variables = {
   
    DB_HOST     = google_sql_database_instance.cloudsql_instance.private_ip_address
    DB_USER     = var.user
    DB_PASS     = random_password.password.result
    DB_NAME     = var.databasename
    DB_PORT     = 3306
  }
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
   


    vpc_connector                 = google_vpc_access_connector.vpc_connector.name
    vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
    }
 
    event_trigger {
    trigger_region = "us-east4"
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.verify_email.id
    service_account_email = google_service_account.cloudfunction_service_account.email
    retry_policy = "RETRY_POLICY_RETRY"
  }
  }


resource "google_service_account" "vm_service_account" {
  account_id   = "vm-service-account"
  display_name = "Service Account for VM Instance"
  project = var.project_id
}
#IAM bindings to service account
resource "google_project_iam_binding" "logging_admin" {
  project = var.project_id
  role    = "roles/logging.admin"
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}",
  ]
}

resource "google_project_iam_binding" "monitoring_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}",
  ]
}
resource "google_project_iam_binding" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.vm_service_account.email}"]
}
#service account for cloud function
resource "google_service_account" "cloudfunction_service_account" {
  account_id   = "cloud-service-account"
  display_name = "Service Account for cloud function"
  project = var.project_id
 }

  # New Cloud Run invoker role
resource "google_project_iam_binding" "cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  members = ["serviceAccount:${google_service_account.cloudfunction_service_account.email}"]
}

resource "google_project_service" "service_networking" {
  service = "servicenetworking.googleapis.com"
  project = var.project_id
}

resource "google_compute_global_address" "private_ip_address" {
  name          ="google-managed-services-${var.vpc_name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  deletion_policy = "ABANDON"

  
   
}

resource "google_vpc_access_connector" "vpc_connector" {
  name          = "new-webapp-vpc-connector"
  network       = google_compute_network.vpc.self_link
  region        = var.region
  ip_cidr_range = "10.2.0.0/28"

}

 resource "google_storage_bucket" "serverless-bucket" {
  name     = "udaygattuuuuuuuu2"
  location = var.region
  storage_class = "STANDARD"
  encryption {
    default_kms_key_name = google_kms_crypto_key.cloudStorage_key.id
  }
  depends_on = [ google_kms_crypto_key_iam_binding.encrypter_decrypter ]

  uniform_bucket_level_access = true

}
 
resource "google_storage_bucket_object" "serverless-archive" {
  name   = "serverless.zip"
  bucket = google_storage_bucket.serverless-bucket.name
  source = "./serverless.zip"
}

resource "google_sql_database_instance" "cloudsql_instance" {
  name                = var.Sql_instance_name
  region              = var.region
  database_version    = var.database_version
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]
  encryption_key_name = google_kms_crypto_key.cloudSql_key.id

  settings {
    tier              = var.tier
    availability_type = var.routing_mode
    disk_type         = var.sql_disk_type
    disk_size         = var.disk_size
    disk_autoresize   = true
 
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.self_link
      enable_private_path_for_google_cloud_services = true
    }
    
    backup_configuration {
      start_time = "03:00"
      enabled            = true
      binary_log_enabled = true
    }
  }
}

resource "google_sql_database" "webapp_database" {
  name     = var.databasename
  instance = google_sql_database_instance.cloudsql_instance.name
}
 
resource "random_password" "password" {
  length  = 16
  special =false
}

resource "google_sql_user" "webapp_user" {
  name     = var.user
  instance = google_sql_database_instance.cloudsql_instance.name
  password = random_password.password.result
  host     = "%"
}

data "google_dns_managed_zone" "my_dns_zone" {
  name        = "udaygattu"
}
 
resource "google_dns_record_set" "my_dns_record" {
  name         = data.google_dns_managed_zone.my_dns_zone.dns_name
  type         = var.dns_type
  ttl          = var.record_ttl
  managed_zone = data.google_dns_managed_zone.my_dns_zone.name
  rrdatas      = [google_compute_global_forwarding_rule.webapp_forwarding_rule.ip_address]

}



output "vm_static_ip" {
  value = google_compute_address.static_ip.address
}

output "cloudsql_private_ip" {
  value = google_sql_database_instance.cloudsql_instance.ip_address
}


resource "google_compute_health_check" "webapp_health_check" {
  name               = "webapp-health-check"
  check_interval_sec = var.interval_time
  timeout_sec        = var.time_out
  healthy_threshold   = var.healthy_threshold
  unhealthy_threshold = var.unhealthy_threshold


  http_health_check {
    port    = var.app_port
    request_path = var.request_path
  }
}
 
 
resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  name   = "webapp-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.webapp_group_manager.id
 
  autoscaling_policy {
    max_replicas    = var.max
    min_replicas    = var.min
    cooldown_period = var.cooldown
 
    cpu_utilization {
      target = var.targetcpu
    }
  }
}
resource "google_compute_managed_ssl_certificate" "webapp_ssl_cert" {
  name = var.ssl
  managed {
    domains = [var.domain_name]
  }
}
 
 
resource "google_compute_region_instance_group_manager" "webapp_group_manager" {
  name     = "webapp-group-manager"
  region   = var.region
  base_instance_name = "webapp"
  distribution_policy_zones = var.distributionzones
  target_size        = var.target_size
 
 
 
  version {
    name = "primary"
    instance_template = google_compute_region_instance_template.vm_template.self_link
  }
 
  named_port {
    name = var.namedp
    port = var.named_port
  }
 
  auto_healing_policies {
   
    health_check = google_compute_health_check.webapp_health_check.self_link
    initial_delay_sec = var.initial_delay_sec
  }
 
}
 

resource "google_compute_url_map" "webapp_url_map" {
  name            = var.urlname
  default_service = google_compute_backend_service.webapp_backend_service.self_link
}
 
resource "google_compute_target_https_proxy" "webapp_https_proxy" {
  name             = "myproxy"
  url_map          = google_compute_url_map.webapp_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.webapp_ssl_cert.self_link]
}
resource "google_compute_global_address" "lb_ipv4_address" {
 
  name = "lb-ipv4-address"
}
resource "google_compute_global_forwarding_rule" "webapp_forwarding_rule" {
  name                  = "forwardingrules"
  ip_protocol           = var.ip_protocol
  load_balancing_scheme = var.scheme
  ip_address            = google_compute_global_address.lb_ipv4_address.address
  port_range            =  var.loadbalancerport
  target                = google_compute_target_https_proxy.webapp_https_proxy.id
}
resource "google_compute_firewall" "webapp-health-check" {
  name          = "webapp-health-check"
  direction     = var.direction
  network       = google_compute_network.vpc.self_link
  source_ranges = var.loadbalancerrange
  allow {
    protocol = var.protocol
    ports    = [var.app_port]
  }
  target_tags = var.tag
}

resource "google_compute_region_instance_template" "vm_template" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  tags         = ["load-balanced-balance"]

  disk {
     
      source_image = var.vm_image
       auto_delete  = true
       boot         = true
      type  = var.vm_disk_type
      disk_size_gb = var.vm_disk_size_gb
    }
  

  network_interface {
    subnetwork = google_compute_subnetwork.webapp_subnet.name

    access_config {
       network_tier = "PREMIUM"


      
    }
  }
  region = var.region
   service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = "#!/bin/bash\ncat <<EOF > /opt/.env\nDB_HOST=${google_sql_database_instance.cloudsql_instance.private_ip_address}\nDB_NAME=${google_sql_database.webapp_database.name}\nDB_USER=${google_sql_user.webapp_user.name}\nDB_PASSWORD=${random_password.password.result}\ndialect=\"mysql\"\nDB_PORT=3306\nproject_id=${var.project_id}\n EOF\n\nchown csye6225:csye6225 /opt/.env\n"
  }
  #   metadata_startup_script = "#!/bin/bash\ncat <<EOF > /opt/.env\n DB_HOST = ${google_sql_database_instance.cloudsql_instance.private_ip_address}\n  DB_NAME = webapp\n  DB_USER= webapp\n  DB_PASSWORD= ${random_password.password.result}\ndialect=\"mysql\"\n  DB_PORT= 3306\nproject_id=${var.project_id}\n  EOF\n\n  chown csye6225:csye6225 /opt/.env\n"


 
}


resource "google_compute_backend_service" "webapp_backend_service" {
  name                  = "backendservicename"
  load_balancing_scheme = var.scheme
  port_name             = var.port_name
  protocol              = var.webapp_protocol
  timeout_sec           = var.timeout_sec
  session_affinity      = "NONE"
  health_checks         = [google_compute_health_check.webapp_health_check.self_link]
 
  backend {
    group           = google_compute_region_instance_group_manager.webapp_group_manager.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = var.targetcpu
  }
}
 

resource "google_kms_key_ring" "webapp_keyring" {
  name = "webapp-keyring-10"
  location = var.region
}

resource "google_kms_crypto_key" "vm_machine_key" {
  name="vm-machine-key-1"
  key_ring = google_kms_key_ring.webapp_keyring.id
  rotation_period = "2592000s"
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "cloudSql_key" {
  name = "cloud-sql-key-1"
  key_ring = google_kms_key_ring.webapp_keyring.id
  rotation_period = "2592000s"
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "cloudStorage_key" {
  name = "cloud-storage-key-1"
  key_ring = google_kms_key_ring.webapp_keyring.id
  rotation_period = "2592000s"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key_iam_binding" "cloudSql_crypto_key" {
  crypto_key_id = google_kms_crypto_key.cloudSql_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [ 
    "serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}"
   ]
}

resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  provider = google-beta
  project = var.project_id
  service = "sqladmin.googleapis.com"
}

data "google_storage_project_service_account" "googlecloudserviceacc"{

}
resource "google_kms_crypto_key_iam_binding" "encrypter_decrypter" {
  crypto_key_id = google_kms_crypto_key.cloudStorage_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = ["serviceAccount:${data.google_storage_project_service_account.googlecloudserviceacc.email_address}"
            ]
}

data "google_project" "project" {}

resource "google_kms_crypto_key_iam_binding" "vm_encrypter_decrypter" {
  crypto_key_id = google_kms_crypto_key.vm_machine_key.id
  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com",
  ]
  
}

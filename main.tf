provider "google" {
  project = var.project_id
  region = var.region
}
data "google_compute_zones" "this" {
  region  = var.region
  project = var.project_id
}
# creating vpc
resource "google_compute_network" "vpc" { #done
  name  =  var.vpc_name
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
  routing_mode = var.routing_mode
}
# creating subnets

resource "google_compute_subnetwork" "webapp_subnet" { #done
  name = "${var.vpc_name}-webapp"
  region = var.region
  network = google_compute_network.vpc.id
 ip_cidr_range = var.webapp_subnet_cidr
 private_ip_google_access = false
}

resource "google_compute_subnetwork" "db_host" { #done
  name = "${var.vpc_name}-db"
  region = var.region
  network = google_compute_network.vpc.id
  ip_cidr_range = var.db_subnet_cidr
  private_ip_google_access = false
  
}

#creating routes
resource "google_compute_route" "internet_access" {  #done
  name = "${var.vpc_name}-internet-access"
  network = google_compute_network.vpc.id
  dest_range = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority = 900
  depends_on = [ google_compute_subnetwork.webapp_subnet ]
}


resource "google_compute_firewall" "allow_web" {    #done
  name = "${var.vpc_name}-allow-web"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports = [var.app_port]
  }
  # source_ranges = ["0.0.0.0/0"]
   source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]

}

resource "google_compute_firewall" "block_ssh" {  #done
  name ="${var.vpc_name}-block-ssh"
  network = google_compute_network.vpc.name

  deny {
    protocol = "tcp"
    ports = ["22"]

  }
  source_ranges = [ "0.0.0.0/0" ]
  priority = 1000
  
}

resource "google_compute_region_instance_template" "vm_template" {
  name = var.vm_name
  machine_type = var.vm_machine_type
  tags = ["load-balanced-balance"]

  disk{
    source_image = var.vm_image
    auto_delete = true
    boot = true
    type = var.vm_disk_type
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
    email = google_service_account.vm_service_account.email
    scopes = ["cloud-platform"]
  }
  
  metadata = {
    startup-script = "#!/bin/bash\n  cat<<EOF>/opt/.env\n  DB_HOST = ${google_sql_database_instance.cloudsql_instance.private_ip_address}\n  DB_NAME = webapp\n  DB_USER= webapp\n  DB_PASSWORD= ${random_password.password.result}\ndialect=\"mysql\"\n  DB_PORT= 3306\n  EOF\n\n  chown csye6225:csye6225 /opt/.env\n  chmod 600 /opt/.env\n  systemctl restart web-app\n\n  EOT\n"
  }
}

resource "google_compute_instance" "vm_instance" {  #done
  name = var.vm_name
  zone = var.vm_zone
  machine_type = var.vm_machine_type

  boot_disk {
    initialize_params {
      image = var.vm_image
      type = var.vm_disk_type
      size = var.vm_disk_size_gb
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.webapp_subnet.id
    network = google_compute_network.vpc.id

      access_config{
        nat_ip = google_compute_address.static_ip.address
    
  }
  }
  # service_account {
  #   scopes = ["cloud-platform"]
  #   email = var.email
  # }

#  metadata = {
#     startup-script = "#!/bin/bash\n  cat<<EOF>/opt/web-app/.env\n  DB_HOST = ${google_sql_database_instance.cloudsql_instance.private_ip_address}\n  DB_NAME = webapp\n  DB_USER= webapp\n  DB_PASSWORD= ${random_password.password.result}\n  DB_PORT= 3306\n  EOF\n\n  chown csye6225:csye6225 /opt/web-app/.env\n  chmod 600 /opt/web-app/.env\n  systemctl restart web-app\n\n  EOT\n"
#   }
 metadata = {
    startup-script = "#!/bin/bash\n  cat<<EOF>/opt/.env\n  DB_HOST = ${google_sql_database_instance.cloudsql_instance.private_ip_address}\n  DB_NAME = webapp\n  DB_USER= webapp\n  DB_PASSWORD= ${random_password.password.result}\ndialect=\"mysql\"\n  DB_PORT= 3306\n  EOF\n\n  chown csye6225:csye6225 /opt/.env\n  chmod 600 /opt/.env\n  systemctl restart web-app\n\n  EOT\n"
  }
  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["cloud-platform"]
  }

}

resource "google_project_service" "service_networking" { #done
  service = "servicenetworking.googleapis.com"
  project = var.project_id
}

resource "google_compute_global_address" "private_ip_range" {  #done
  provider = google-beta
  project = var.project_id
  name = "google-managed-services-${var.vpc_name}"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 24
  network = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {   #done
  network = google_compute_network.vpc.id
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [ google_compute_global_address.private_ip_range.name ]
  deletion_policy = "ABANDON"
  # depends_on = [ google_project_service.service_networking ]
  }
 



resource "google_sql_database_instance" "cloudsql_instance" {   #done
  provider = google-beta
  project = var.project_id
  # name = "${var.cloudsql_instance_name}"
  name = var.cloudsql_instance_name
  database_version = var.cloudsql_database_version
  region = "${var.region}"
  deletion_protection = false

  settings {
    tier = var.cloudsql_instance_tier
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.vpc.self_link
      # require_ssl = var.cloudsql_require_ssl
      enable_private_path_for_google_cloud_services = true
    }
    disk_type = var.cloudsql_disk_type
    disk_size = var.cloudsql_disk_size
    disk_autoresize = var.cloudsql_disk_autoresize
    backup_configuration {
      enabled = true
      binary_log_enabled = true
    }
    availability_type = "REGIONAL"

    # database_flags {
    #    name  = "log_bin"
    #    value = "ON"
    # }
    #     database_flags {
    #     name  = "binlog_format"
    #     value = "ROW"
    #   }

  }
  depends_on = [google_service_networking_connection.private_vpc_connection]
}


resource "google_sql_database" "webapp_database" {  #done
  name = "webapp"
  instance = google_sql_database_instance.cloudsql_instance.name
}


resource "random_password" "password" {   #done
  length = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_sql_user" "user" { #done
  name = "webapp"
  instance = google_sql_database_instance.cloudsql_instance.name
  password = random_password.password.result
  host = "%"
}

 output "cloudsql_private_ip" { #done
    value = google_sql_database_instance.cloudsql_instance.ip_address
  }

output "vm_static_ip" { #done
  value = google_compute_address.static_ip.address
}
resource "google_compute_address" "static_ip" {   #done
  name   = "vm-static-ip"
  region = var.region
}

resource "google_service_account" "vm_service_account" { #done
  account_id   = "vm-service-account"
  display_name = "Service Account for VM Instance"
  project = var.project_id
}
#IAM bindings to service account
resource "google_project_iam_binding" "logging_admin" {   #done
  project = var.project_id
  role    = "roles/logging.admin"
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}",
  ]
}

resource "google_project_iam_binding" "monitoring_metric_writer" {  #done
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}",
  ]
}
resource "google_project_iam_binding" "cloud_run_invoker" {  #done
  project = var.project_id
  role="roles/run.invoker"
  members = ["serviceAccount:${google_service_account.vm_service_account.email}"]
  
}

resource "google_project_iam_binding" "pubsub_publisher" {     #done
  project = var.project_id
  role = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.vm_service_account.email}"]
}


# resource "google_project_iam_binding" "function_invoker" {
#   project = var.project_id
#   role    = "roles/cloudfunctions.invoker"
#   members = [
#     "serviceAccount:${google_service_account.vm_service_account.email}",
#   ]
# }

# resource "google_project_iam_binding" "cloudsql_client" {
#   project = var.project_id
#   role    = "roles/cloudsql.client"
#   members = [
#     "serviceAccount:${google_service_account.vm_service_account.email}",
#   ]
# }
# resource "google_project_iam_binding" "service_account_user" {
#   project = var.project_id
#   role    = "roles/iam.serviceAccountUser"
#   members = [
#     "serviceAccount:${google_service_account.vm_service_account.email}",
#   ]
# }

# resource "google_project_iam_binding" "service_account_token_creator" {
#   project = var.project_id
#   role    = "roles/iam.serviceAccountTokenCreator"
#   members = [
#     "serviceAccount:service-${var.project_id}@gcp-sa-pubsub.iam.gserviceaccount.com",
#   ]
# }

data "google_dns_managed_zone" "my_dns_zone" { #done
  name        = "udaygattu"
}
 
resource "google_dns_record_set" "my_dns_record" {  #done
  name         = data.google_dns_managed_zone.my_dns_zone.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.my_dns_zone.name
  rrdatas      = [google_compute_address.static_ip.address]

}


resource "google_pubsub_topic" "verify_email" {  #done
  name="verify_email"
  message_retention_duration = "604800s"
}

resource "google_pubsub_subscription" "verify_email_subscription" {  #done
  name = "verify_email_subscription"
  topic = google_pubsub_topic.verify_email.name
  ack_deadline_seconds = 20
  push_config {
    push_endpoint = google_cloudfunctions2_function.verify_email_function.url
  }
}

resource "google_vpc_access_connector" "vpc_connector" {  #done
  name = "new-webapp-vpc-connector" 
  network = google_compute_network.vpc.self_link
  region = var.region
  ip_cidr_range = "10.2.0.0/28"
}

resource "google_storage_bucket" "serverless-bucket" { #done
  name= "udaygattubucket1"
  location = "US"
}

resource "google_storage_bucket_object" "serverless-archive" { #done
  name = "serverless.zip"
  bucket = google_storage_bucket.serverless-bucket.name
  # source = "../serverless.zip"
  source = "./serverless.zip"
}

resource "google_cloudfunctions2_function" "verify_email_function" { #done
  depends_on = [ google_vpc_access_connector.vpc_connector ]
  name="verify-email-function"
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
    max_instance_count = 3
    min_instance_count = 2
    available_memory = "256Mi"
    available_cpu = 1
    timeout_seconds = 540
    max_instance_request_concurrency = 1
    environment_variables = {
      DB_HOST= google_sql_database_instance.cloudsql_instance.private_ip_address
      DB_USER= "webapp"
      DB_PASSWORD= random_password.password.result
      DB_NAME="webapp"
      DB_PORT=3306

    }
    ingress_settings =  "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    vpc_connector = google_vpc_access_connector.vpc_connector.name
    vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
  }
  event_trigger {
    trigger_region = "us-east4"
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.verify_email.id
    service_account_email = google_service_account.vm_service_account.email
    retry_policy = "RETRY_POLICY_RETRY"
  }
  
}

resource "google_compute_health_check" "webapp_health_check" {
  name = "webapp-health-check"
  check_interval_sec = var.interval_time
  timeout_sec = var.time_out
  healthy_threshold = var.healthy_threshold
  unhealthy_threshold = var.unhealthy_threshold

  http_health_check {
    port = var.app_port
    request_path = var.request_path

  }
}

resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  
  name = "webapp-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.webapp_group_manager.id

  autoscaling_policy {
    max_replicas = var.max
    min_replicas = var.min
    cooldown_period = var.cooldown
  cpu_utilization {
    target= var.targetcpu
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
  name ="webapp-group-manager"
  region = var.region
  base_instance_name = "webapp"
  distribution_policy_zones = var.distributionzones
  target_size = var.target_size

  version {
    name = "primary"
    instance_template = google_compute_region_instance_template.vm_template.self_link
  }
  named_port {
    name=var.namedp
    port = var.named_port
  }
  auto_healing_policies {
    health_check = google_compute_health_check.webapp_health_check.self_link
    initial_delay_sec = var.initial_delay_sec
  }
}

resource "google_compute_backend_service" "webapp_backend_service" {
  name = "backendservicename"
  load_balancing_scheme = var.scheme
  port_name = var.port_name
  protocol = var.webapp_protocol
  timeout_sec = var.timeout_sec
  session_affinity = "NONE"
  health_checks = [google_compute_health_check.webapp_health_check.self_link]

  backend {
    group = google_compute_region_instance_group_manager.webapp_group_manager.instance_group
    balancing_mode = "UTILIZATION"
    capacity_scaler = var.targetcpu

  }
  
}

resource "google_compute_url_map" "webapp_url_map" {
  name = var.urlname
  default_service = google_compute_backend_service.webapp_backend_service.self_link
}
resource "google_compute_target_https_proxy" "webapp_https_proxy" {
  name = "proxyname"
  url_map = google_compute_url_map.webapp_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.webapp_ssl_cert.self_link]
}

resource "google_compute_global_address" "lb_ipv4_address" {
  name = "lb-ipv4-address"
}

resource "google_compute_global_forwarding_rule" "webapp_forwarding_rule" {
  name = "forwardingrulename"
  ip_protocol = var.ip_protocol
  load_balancing_scheme = var.scheme
  ip_address = google_compute_global_address.lb_ipv4_address.address
  port_range = var.loadbalancerport
  target = google_compute_target_https_proxy.webapp_https_proxy.id
}

resource "google_compute_firewall" "webapp_health_check" {
  name = "webapphealthcheck"
  direction = google_compute_network.vpc.self_link
  network = var.loadbalancerrange
  allow {
    protocol = var.protocol
    ports = [var.app_port]
  }
  target_tags = var.tag
}

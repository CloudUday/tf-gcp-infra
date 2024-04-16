

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC to create"
  type        = string
}

variable "webapp_subnet_cidr" {
  description = "CIDR for the webapp subnet"
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR for the db subnet"
  type        = string
}

variable "vm_name" {
  description = "The name of the VM instance"
  type        = string
}

variable "vm_zone" {
  description = "The zone for the VM instance"
  type        = string
}

variable "vm_machine_type" {
  description = "The machine type for the VM instance"
  type        = string
}

variable "vm_image" {
  description = "The custom image for the VM boot disk"
  type        = string
}

variable "vm_disk_type" {
  description = "The disk type for the VM boot disk"
  type        = string
}

variable "vm_disk_size_gb" {
  description = "The size of the VM boot disk in GB"
  type        = number
}

variable "app_port" {
  description = "The application port to allow through the firewall"
  type        = string
}

variable "ssh_port" {
  description = "The SSH port to allow through the firewall"
  type        = string
}

variable "Sql_instance_name" {
  description = "The name of the Cloud SQL instance"
  type        = string
}

variable "database_version" {
  description = "The database version for the Cloud SQL instance"
  type        = string
}

variable "routing_mode" {
  description = "The routing mode for the VPC"
  type        = string
}

variable "vpc_private_service_access" {
  description = "Configuration for VPC private service access"
  type        = string
}

variable "private_ip_address" {
  description = "Private IP address for the service"
  type        = string
}

variable "forwarding_rule_private_access" {
  description = "Name of the forwarding rule for private access"
  type        = string
}

variable "private_access_address_type" {
  description = "Type of address for private access"
  type        = string
}

variable "db_deletion_protection" {
  description = "Whether deletion protection is enabled for the DB"
  type        = bool
}

variable "ipv4_enabled" {
  description = "Whether IPv4 is enabled for the DB"
  type        = bool
}

variable "sql_disk_type" {
  description = "The disk type for the Cloud SQL instance"
  type        = string
}

variable "disk_size" {
  description = "The disk size for the Cloud SQL instance in GB"
  type        = number
}

variable "tier" {
  description = "The tier (machine type) for the Cloud SQL instance"
  type        = string
}

variable "databasename" {
  description = "The name of the database to create in the Cloud SQL instance"
  type        = string
}

variable "user" {
  description = "The username for the database in the Cloud SQL instance"
  type        = string
}

variable "Destination_range" {
  description = "Destination range for the VPC routes"
  type        = string
}

variable "source_ranges" {
  description = "Source ranges for the firewall rules"
  type        = string
}

variable "db_edition" {
  description = "Edition of the database"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the SSL certificate"
  type        = string
}

variable "ssl" {
  description = "The name of the SSL certificate"
  type        = string
}

variable "max" {
  description = "Maximum number of instances for autoscaling"
  type        = number
}

variable "min" {
  description = "Minimum number of instances for autoscaling"
  type        = number
}

variable "cooldown" {
  description = "Cooldown period for autoscaling"
  type        = number
}

variable "urlname" {
  description = "Name for the URL map"
  type        = string
}

variable "targetcpu" {
  description = "Target CPU utilization for autoscaling"
  type        = number
}

variable "target_tags" {
  description = "Tags for the target instances"
  type        = list(string)
}

variable "priorityvalue" {
  description = "Priority value for routing"
  type        = number
}

variable "protocol" {
  description = "Protocol for the firewall rule"
  type        = string
}

variable "direction" {
  description = "Direction for the firewall rule"
  type        = string
}

variable "loadbalancerport" {
  description = "Port for the load balancer"
  type        = string
}

variable "scheme" {
  description = "Scheme for the load balancing (EXTERNAL, INTERNAL)"
  type        = string
}

variable "ip_protocol" {
  description = "IP protocol for the forwarding rule"
  type        = string
}

variable "port_name" {
  description = "Port name for the backend service"
  type        = string
}

variable "webapp_protocol" {
  description = "Protocol for the web application"
  type        = string
}

variable "timeout_sec" {
  description = "Timeout in seconds for the health check"
  type        = number
}

variable "initial_delay_sec" {
  description = "Initial delay in seconds for auto-healing"
  type        = number
}

variable "time_out" {
  description = "Timeout value"
  type        = number
}

variable "distributionzones" {
  description = "Zones for distribution policy"
  type        = list(string)
}

variable "target_size" {
  description = "Target size for the instance group"
  type        = number
}

variable "unhealthy_threshold" {
  description = "Unhealthy threshold for health checks"
  type        = number
}

variable "healthy_threshold" {
  description = "Healthy threshold for health checks"
  type        = number
}

variable "interval_time" {
  description = "Interval time for health checks"
  type        = number
}

variable "tag" {
  description = "Tags for firewall rule targets"
  type        = list(string)
}

variable "loadbalancerrange" {
  description = "IP range for the load balancer"
  type        = list(string)
}

variable "named_port" {
  description = "Named port for the instance group"
  type        = number
}

variable "namedp" {
  description = "Name for the named port"
  type        = string
}

variable "request_path" {
  description = "Request path for the health check"
  type        = string
}

variable "record_ttl" {
  description = "TTL for the DNS record"
  type        = number
}

variable "dns_type" {
  description = "DNS record type"
  type        = string
}

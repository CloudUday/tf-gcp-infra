variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-east4"
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
  description = "The zone for the VM  instance"
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

variable "cloudsql_instance_name" {
  description = "The name of the Cloud SQL instance"
  type        = string
}

variable "cloudsql_database_version" {
  description = "The database version for the Cloud SQL instance"
  type        = string
  default     = "MYSQL_5_7"
}

variable "cloudsql_instance_tier" {
  description = "The tier (machine type) for the Cloud SQL instance"
  type        = string
  default     = "db-f1-micro"
}

variable "cloudsql_require_ssl" {
  description = "Whether SSL connections are required for the Cloud SQL instance"
  type        = bool
  default     = true
}

variable "cloudsql_disk_type" {
  description = "The disk type for the Cloud SQL instance"
  type        = string
  default     = "PD_SSD"
}

variable "cloudsql_disk_size" {
  description = "The disk size for the Cloud SQL instance in GB"
  type        = number
  default     = 100
}

variable "cloudsql_disk_autoresize" {
  description = "Whether the Cloud SQL instance disk should be auto-resizable"
  type        = bool
  default     = true
}

variable "db_port" {
  description = "value"
  type = number
  default = 3306
  
}
variable "routing_mode" {
  description = "value"
}
variable "email" {
  description = "service_email"
}

variable "db_port" {
  description = "value"
}

variable "routing_mode" {
  description = "value"
}
variable "ssl" {
  description = "value"
}
variable "max" {
  description = "value"
}
variable "min" {
  description = "value"
}

variable "cooldown" {
  description = "value"
}

variable "urlname" {
  description = "value"
}
variable "targetcpu" {
  description = "value"
}
variable "target_tags" {
  description = "value"
}
variable "priorityvalue" {
  description = "value"
}
variable "direction" {
  description = "value"
}
variable "loadbalancerport" {
  description = "value"
}
variable "scheme" {
  description = "value"
}
variable "ip_protocol" {
  description = "value"
}

variable "port_name" {
  description = "value"
}

variable "webapp_protocol" {
  description = "value"
}
variable "timeout_sec" {
  description = "value"
}
variable "initial_delay_sec" {
  description = "value"
}
variable "time_out" {
  description = "value"
}
variable "distributionzones" {
  description = "value"
}
variable "target_size" {
  description = "value"
}
variable "unhealthy_threshold" {
  description = "value"
}
variable "healthy_threshold" {
  description = "value"
}
variable "interval_time" {
  description = "value"
}
variable "tag" {
  description = "value"
}
variable "loadbalancerrange" {
  description = "value"
}
variable "named_port" {
  description = "value"
}
variable "namedp" {
  description = "value"
}
variable "request_path" {
  description = "value"
}
variable "record_ttl" {
  description = "value"
}
variable "dns_type" {
  description = "value"
}

variable "domain_name" {
  description = "value"
}

variable "protocol" {
  description = "value"
}
variable "project_id" {
  description = "Your Project ID"
  type        = string
}

variable "region" {
  description = "select region"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "my-vpc"
}

variable "environment" {
  description = "The deployment environment."
  type        = string
}

variable "app_name" {
  description = "The name of the application."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy the RDS instance into."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "k8s_vpc_cidr" {
  description = "The CIDR block of the Kubernetes cluster's VPC."
  type        = string
}

variable "db_allocated_storage" {
  description = "The allocated storage for the RDS instance."
  type        = number
}

variable "db_instance_class" {
  description = "The instance class for the RDS instance."
  type        = string
}

variable "db_username" {
  description = "The master username for the database."
  type        = string
}

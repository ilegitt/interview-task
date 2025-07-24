variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string
}

variable "app_name" {
  description = "The name of the application."
  type        = string
}

variable "db_vpc_name" {
  description = "The name tag of the existing VPC for the database."
  type        = string
}

variable "k8s_vpc_cidr" {
  description = "The CIDR block of the Kubernetes cluster's VPC (the peered VPC)."
  type        = string
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
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
  default     = "admin"
}

output "db_instance_endpoint" {
  value       = module.rds_db.db_instance_endpoint
  description = "The endpoint of the RDS instance."
}

output "db_credentials_secret_arn" {
  value       = module.rds_db.db_credentials_secret_arn
  description = "The ARN of the secret containing the DB credentials."
}

output "db_host_for_k8s" {
  value       = module.rds_db.db_instance_address
  description = "The address of the RDS instance for K8s ServiceEntry."
}

output "app_service_account_role_arn" {
  value       = aws_iam_role.app_sa_role.arn
  description = "The ARN of the IAM role for the application's service account."
}

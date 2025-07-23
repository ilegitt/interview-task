output "db_instance_endpoint" {
  value       = aws_db_instance.default.endpoint
  description = "The endpoint of the RDS instance."
}

output "db_instance_address" {
  value       = aws_db_instance.default.address
  description = "The address of the RDS instance."
}

output "db_credentials_secret_arn" {
  value       = aws_secretsmanager_secret.db_credentials.arn
  description = "The ARN of the secret containing the DB credentials."
}

output "secrets_policy_arn" {
  value       = aws_iam_policy.secrets_policy.arn
  description = "The ARN of the IAM policy for accessing the secret."
}

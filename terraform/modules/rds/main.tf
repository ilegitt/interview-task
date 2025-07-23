# Generate a random password for the database
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a security group for the RDS instance
resource "aws_security_group" "db_sg" {
  name        = "${var.app_name}-${var.environment}-db-sg"
  description = "Allow traffic to the RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432 # PostgreSQL port
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.k8s_vpc_cidr]
    description = "Allow inbound from K8s VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-db-sg"
    Environment = var.environment
  }
}

# Create a DB subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.app_name}-${var.environment}-sng"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.app_name}-${var.environment}-sng"
    Environment = var.environment
  }
}

# Create the RDS instance
resource "aws_db_instance" "default" {
  identifier             = "${var.app_name}-${var.environment}-db"
  allocated_storage      = var.db_allocated_storage
  engine                 = "postgres"
  engine_version         = "14.5"
  instance_class         = var.db_instance_class
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  username               = var.db_username
  password               = random_password.db_password.result
  skip_final_snapshot    = true
  tags = {
    Name        = "${var.app_name}-${var.environment}-db"
    Environment = var.environment
  }
}

# Store the database credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.app_name}/${var.environment}/db_credentials"
  description = "Database credentials for ${var.app_name} in ${var.environment}"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.default.username
    password = aws_db_instance.default.password
    engine   = aws_db_instance.default.engine
    host     = aws_db_instance.default.address
    port     = aws_db_instance.default.port
    dbname   = var.app_name
  })
}

# IAM Policy to allow access to the secret
data "aws_iam_policy_document" "secrets_policy_doc" {
  statement {
    sid    = "AllowAppToReadDBCredentials"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      aws_secretsmanager_secret.db_credentials.arn,
    ]
  }
}

resource "aws_iam_policy" "secrets_policy" {
  name   = "${var.app_name}-${var.environment}-secrets-policy"
  policy = data.aws_iam_policy_document.secrets_policy_doc.json
}

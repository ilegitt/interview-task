provider "aws" {
  region = var.aws_region
}

# Data source for the Database VPC where the RDS instance will be deployed
data "aws_vpc" "db_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.db_vpc_name]
  }
}

# Data source for the private subnets within the Database VPC
data "aws_subnets" "db_private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.db_vpc.id]
  }
  tags = {
    Tier = "Private"
  }
}

# Data source for the EKS cluster to get its OIDC provider URL
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

# IAM policy document to allow the K8s service account to assume a role
data "aws_iam_policy_document" "app_k8s_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.app_name}-${var.environment}:${var.app_name}-${var.environment}"]
    }
  }
}

# Create the IAM Role for the Service Account (IRSA)
resource "aws_iam_role" "app_sa_role" {
  name               = "${var.app_name}-${var.environment}-sa-role"
  assume_role_policy = data.aws_iam_policy_document.app_k8s_assume_role_policy.json
}

# Calling the reusable RDS module
module "rds_db" {
  source = "./modules/rds"

  # Pass variables to the module
  environment          = var.environment
  app_name             = var.app_name
  db_vpc_id            = data.aws_vpc.db_vpc.id
  db_private_subnet_ids= data.aws_subnets.db_private_subnets.ids
  k8s_vpc_cidr         = var.k8s_vpc_cidr # From the peered EKS VPC
  db_allocated_storage = var.db_allocated_storage
  db_instance_class    = var.db_instance_class
  db_username          = var.db_username
}

# Attach the secrets policy to the role
resource "aws_iam_role_policy_attachment" "app_sa_secrets_policy_attach" {
  role       = aws_iam_role.app_sa_role.name
  policy_arn = module.rds_db.secrets_policy_arn
}

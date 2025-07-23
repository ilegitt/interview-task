provider "aws" {
  region = var.aws_region
}

# Data sources for existing VPC, subnets, and EKS cluster OIDC
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  tags = {
    Tier = "Private"
  }
}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

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
      # This now correctly and predictably matches the namespace and service account name created by Helm.
      # e.g., system:serviceaccount:my-app-dev:my-app-dev
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
  vpc_id               = data.aws_vpc.existing.id
  private_subnet_ids   = data.aws_subnets.private.ids
  k8s_vpc_cidr         = var.k8s_vpc_cidr
  db_allocated_storage = var.db_allocated_storage
  db_instance_class    = var.db_instance_class
  db_username          = var.db_username
}

# Attach the secrets policy to the role
resource "aws_iam_role_policy_attachment" "app_sa_secrets_policy_attach" {
  role       = aws_iam_role.app_sa_role.name
  policy_arn = module.rds_db.secrets_policy_arn
}

This repository contains a fully automated CI/CD pipeline for deploying an application to an AWS EKS cluster and its dedicated database into a separate, peered VPC.

The solution uses Terraform for infrastructure provisioning, Helm for application packaging, and GitHub Actions for CI/CD orchestration, with a strong focus on security and automation.

KEY FEATURES

Automated Infrastructure: Terraform provisions the AWS RDS instance in a dedicated VPC and manages the necessary IAM roles for zero-trust authentication.

Automated Deployments: Helm packages the application, and GitHub Actions deploys it to different environments based on git branches.

VPC Peering Model: The application runs in an EKS cluster in one VPC, while the database resides in another. Communication is enabled via an existing VPC peering connection.

Secure Credentials Management: The pipeline uses AWS Secrets Manager and the AWS Secrets and Configuration Provider (ASCP) to securely inject database credentials into the application at runtime. 

Zero-Trust Security: Authentication between all components is handled through short-lived tokens and IAM roles (OIDC and IRSA), with no long-lived keys. 

DevSecOps Integration: The pipeline includes automated security scanning (SCA, SAST, DAST).

PREREQUISITES

Before using this pipeline, you must ensure the following are configured in AWS account and EKS cluster. 

1. EKS Cluster and Peered VPCs
You must have an existing Amazon EKS cluster running in one VPC.
You must have a second VPC to host the database.
A VPC Peering Connection must be active between these two VPCs, with route tables configured to allow traffic flow.

2. EKS Cluster with OIDC Provider
You must have an IAM OIDC provider associated with your EKS cluster.

3. AWS Secrets and Configuration Provider (ASCP)
The ASCP EKS add-on must be installed on your cluster. This component is responsible for fetching secrets from AWS Secrets Manager.

4. GitHub Repository Configuration  
You need to configure the following in your GitHub repository settings under Settings > Secrets and variables > Actions:

Secrets:
AWS_CI_ROLE_ARN: The ARN of the IAM role that the GitHub Actions pipeline will assume to deploy infrastructure. This role needs permissions to manage Terraform resources (RDS, IAM) and interact with EKS. 
DOCKERHUB_USERNAME: Your Docker Hub username for pushing container images.	
DOCKERHUB_TOKEN: Your Docker Hub token.	

Variables:
AWS_REGION: The AWS region for deployment.
EKS_CLUSTER_NAME: The name of your EKS cluster.

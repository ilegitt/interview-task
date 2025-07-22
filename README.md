Application and Database Deployment Pipeline This repository contains a fully automated CI/CD pipeline for deploying an application and a dedicated RDS database to a Kubernetes cluster on AWS. The solution uses Terraform for infrastructure provisioning, Helm for application packaging, and GitHub Actions for CI/CD orchestration, with a strong focus on security and automation. 

Key Features

Automated Infrastructure: Terraform provisions the AWS RDS instance, security groups, and the necessary IAM roles for zero-trust authentication.

Automated Deployments: Helm packages the application, and GitHub Actions deploys it to different environments based on git branches.

Secure Credentials Management: The pipeline uses AWS Secrets Manager and the AWS Secrets and Configuration Provider (ASCP) to securely inject database credentials into the application at runtime. 

Zero-Trust Security: Authentication between all components is handled through short-lived tokens and IAM roles (OIDC and IRSA), with no long-lived keys. 

DevSecOps Integration: The pipeline includes automated security scanning: 
SAST/SCA: Trivy scans container images for known vulnerabilities (CVEs) in both OS packages and application libraries. 

DAST: OWASP ZAP scans the running application in staging for common web vulnerabilities. 

Dependency Review: Proactively scans pull requests to prevent vulnerable dependencies from being merged. 

Prerequisites
Before using this pipeline, you must ensure the following are configured in your AWS account and EKS cluster. 

1. EKS Cluster with OIDC Provider 

You must have an existing Amazon EKS cluster with an associated IAM OIDC provider. This is required for both the pipeline (GitHub Actions) and the application pods (IRSA) to authenticate with AWS IAM securely. 

To associate an OIDC provider with your cluster, run: 
eksctl utils associate-iam-oidc-provider --cluster <YOUR_EKS_CLUSTER_NAME> --approve 

2. AWS Secrets and Configuration Provider (ASCP)

The ASCP EKS add-on must be installed on your cluster. This component is responsible for fetching secrets from AWS Secrets Manager.
To install the add-on, run:
aws eks create-addon \
    --cluster-name <YOUR_EKS_CLUSTER_NAME> \
    --addon-name aws-secrets-store-csi-driver

3. GitHub Repository Configuration
   
You need to configure the following in your GitHub repository settings under Settings > Secrets and variables > Actions:
	•	Secrets:
	AWS_CI_ROLE_ARN: The ARN of the IAM role that the GitHub Actions pipeline will assume to deploy infrastructure. This role needs permissions to manage Terraform resources (RDS, IAM)    and interact with EKS. 
 
	DOCKERHUB_USERNAME: Your Docker Hub username for pushing container images.
 
	DOCKERHUB_TOKEN: Your Docker Hub token.
 
	•	Variables:
	AWS_REGION: The AWS region for deployment (e.g., us-east-1).
 
	EKS_CLUSTER_NAME: The name of your EKS cluster. 


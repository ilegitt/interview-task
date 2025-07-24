
This document provides a comprehensive overview of the automated CI/CD pipeline designed to deploy an application and its dedicated database to an AWS EKS cluster.

The solution is built on a foundation of Infrastructure as Code (IaC), GitOps principles, and an integrated DevSecOps toolchain to ensure secure, reliable, and repeatable deployments across multiple environments.

The primary goal is to automate the entire lifecycle, from code commit to a fully operational and scanned application in a Kubernetes environment, with zero manual intervention and a robust zero-trust security posture.

- Core Components
  
Source Control & CI/CD: GitHub and GitHub Actions serve as the source code repository and the automation engine for the entire pipeline.

Infrastructure as Code: Terraform is used to provision and manage all cloud infrastructure resources, including the database, networking rules, and IAM roles.

Application Packaging: Helm packages the Kubernetes application manifests, allowing for versioned, repeatable, and configurable deployments.

Cloud Provider: Amazon Web Services (AWS) hosts the EKS cluster and all supporting infrastructure.

Container Registry: Docker Hub (or any OCI-compliant registry) stores the application's container images.

- Workflow Overview
  
The pipeline follows a Git-centric workflow, where actions in the repository trigger specific automated processes:

Pull Request: A developer opens a pull request. This automatically triggers a Dependency Review scan to check for known vulnerabilities in any new or changed dependencies.

Push to Branch: A commit is pushed to a feature branch (dev), staging, or main.

Build & Scan:

A new container image is built and pushed to the container registry.

Trivy performs Static Application Security Testing (SAST) and Software Composition Analysis (SCA) on the image, scanning for vulnerabilities in OS packages and application libraries.

Deploy Infrastructure:

The pipeline authenticates to AWS using a secure, short-lived OIDC token.

Terraform runs to create or update the infrastructure for the target environment (e.g., RDS database, IAM Role for Service Account).

Deploy Application:

Helm deploys the application to the corresponding namespace in the EKS cluster (e.g., my-app-dev). It injects configuration values from Terraform outputs, such as the database 
secret ARN and the IAM role for the pod.

Dynamic Scan (Staging):

After a successful deployment to the staging environment, an OWASP ZAP scan performs Dynamic Application Security Testing (DAST) against the running application to find runtime 
vulnerabilities.

- Terraform Infrastructure
The infrastructure is managed via a modular and environment-aware Terraform configuration.

Structure: A root configuration (terraform/main.tf) calls a reusable rds module. This promotes code reuse and separation of concerns.

Provisioned Resources:

AWS RDS Instance: A PostgreSQL database instance is created within a specified private subnet in the dedicated Database VPC.

AWS Security Group: A security group is configured to only allow inbound traffic from the CIDR block of the peered EKS VPC, ensuring secure and isolated communication.

AWS Secrets Manager Secret: A secret is created to securely store the randomly generated database credentials (username, password, host, etc.).

IAM Role for Service Account (IRSA): Terraform automatically creates the IAM role that the application's Kubernetes service account will assume. This role has a trust relationship with the EKS OIDC provider and is granted the specific permission to read the database secret from Secrets Manager. This entirely automates the IRSA setup.

Environments: Configuration for each environment (dev, staging, prod) is defined in .tfvars files. The pipeline selects the appropriate file based on the active git branch.

- Helm Chart
  
The application is packaged as a Helm chart located in the app/ directory.

Templates:

deployment.yaml: Defines the Kubernetes Deployment. It includes liveness and readiness probes for health checking and specifies resource requests and limits to ensure stable cluster operation. It also defines the volume mount for the secrets.

service.yaml: Creates a ClusterIP service to expose the application within the cluster.

serviceaccount.yaml: Creates a dedicated Kubernetes Service Account for the application in its namespace. The pipeline annotates this service account with the ARN of the IAM role created by Terraform.

secretproviderclass.yaml: This crucial resource instructs the AWS Secrets and Configuration Provider (ASCP) which secret to fetch from AWS Secrets Manager and how to mount it into the pod.

serviceentry.yaml: An Istio resource that explicitly allows egress traffic from the service mesh to the external RDS database endpoint, satisfying the REGISTRY_ONLY outbound traffic policy.

Configuration: The values.yaml file provides default configurations, which are overridden by the pipeline at deploy time with environment-specific values from Terraform outputs.

- Security Strategy
The solution is built on a zero-trust model and integrates security scanning throughout the pipeline (DevSecOps).

- Authentication and Authorization
Pipeline to AWS: The GitHub Actions workflow authenticates to AWS using OpenID Connect (OIDC). This allows it to assume an IAM role (AWS_CI_ROLE_ARN) using short-lived tokens, completely avoiding the need for static, long-lived AWS access keys.

Pod to AWS: The application pod authenticates to AWS using IAM Roles for Service Accounts (IRSA). The ASCP driver running on the pod uses the annotated service account to assume the IAM role created by Terraform, which grants it permission to call secretsmanager:GetSecretValue.

- Secrets Management
  
Database credentials follow a secure, automated lifecycle:

Creation: Terraform generates a random password for the RDS instance.

Storage: The full connection details (host, port, user, password) are stored as a JSON object in AWS Secrets Manager.

Access: The application's IAM role is granted read-only access only to this specific secret.

Consumption: At runtime, the ASCP mounts the secret as files into the pod's filesystem (/mnt/secrets-store). The application reads the credentials directly from these files. 
Credentials are never exposed as environment variables or in the container image.

- Integrated Security Scanning
Dependency Review (SCA): Prevents vulnerable dependencies from being merged into key branches by scanning pull requests.

Container Image Scan (SAST/SCA): Trivy provides a critical security gate after the build step, failing the pipeline if high-severity vulnerabilities are found in the OS or application libraries.

Dynamic Analysis (DAST): The OWASP ZAP scan provides an additional layer of security by testing the running application for vulnerabilities like XSS and SQLi in a production-like environment.

- Operational Guide

Prerequisites

Before the first run, the target AWS account and EKS cluster require a one-time setup as detailed in the README.md:

The EKS cluster must have an IAM OIDC provider associated with it.

The aws-secrets-store-csi-driver EKS add-on must be installed.

The required secrets and variables must be configured in the GitHub repository settings.

- Deployment Workflow
  
The pipeline is driven by git operations;

To scan a change: Open a pull request against staging or main. The dependency_review job will run.

To deploy to Development: Push or merge a commit to the dev branch.

To deploy to Staging: Push or merge a commit to the staging branch. This will also trigger a DAST scan after deployment.

To deploy to Production: Push or merge a commit to the main branch.

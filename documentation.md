1. Introduction
   
1.1. Purpose
This document provides the complete technical and operational documentation for the automated CI/CD pipeline. The solution is designed to deploy an application and its dedicated database to a secure, multi-VPC environment on AWS, managed entirely through code and automation.

1.2. Scope
The scope of this solution covers the entire lifecycle of an application deployment, from a developer's code commit to a fully operational and scanned application running in a Kubernetes environment. This includes infrastructure provisioning, application packaging, security scanning, and deployment orchestration across multiple environments (development, staging, production).

2. Solution Architecture
The architecture is designed for security, scalability, and separation of concerns, utilizing a peered VPC model. It integrates best-in-class tools for cloud infrastructure, container orchestration, and CI/CD automation.

2.1. Core Components
Source Control & CI/CD: GitHub and GitHub Actions for code management and workflow orchestration.

Infrastructure as Code: Terraform for provisioning all AWS resources. The state is managed remotely in an S3 bucket with DynamoDB for state locking.

Application Packaging: Helm for packaging and deploying Kubernetes manifests.

Cloud Infrastructure: AWS provides the EKS cluster, RDS database, and all supporting services.

Networking: The application resides in an EKS VPC, while the database is isolated in a separate Database VPC. An existing VPC Peering Connection enables secure communication between them.

3. CI/CD Workflow
The pipeline is event-driven, triggered by actions within the GitHub repository. It is composed of several independent jobs that run in a coordinated sequence to build, test, and deploy the application.

3.1. Job Descriptions
dependency_review (On Pull Request): Scans for vulnerabilities in changed dependencies to prevent merging insecure code.

iac_scan (On Push & PR): Performs static analysis on the infrastructure and Helm code using tflint, tfsec, and helm lint to catch misconfigurations and security issues early.

build_and_scan (On Push & PR): Builds the application's Docker image and performs SAST/SCA scanning with Trivy. The image is only pushed to the registry on a push event.

deploy_infra_and_app (On Push): Depends on the success of the scan jobs. It deploys the infrastructure with Terraform and the application with Helm, passing necessary outputs from Terraform to the Helm chart.

dast_scan (On Push to Staging): After a successful deployment to the staging environment, it runs a DAST scan against the live application using OWASP ZAP.

4. Security & DevSecOps Strategy
The solution is built on a zero-trust model with security integrated at every stage.

4.1. Authentication: A Zero-Trust Model
Pipeline to AWS: GitHub Actions authenticates to AWS using OIDC. It assumes an IAM role via a short-lived token, eliminating the need for static access keys.

Pod to AWS: The application authenticates using IAM Roles for Service Accounts (IRSA). The pod's service account is annotated with an IAM role ARN, allowing it to securely fetch secrets from AWS Secrets Manager without any embedded credentials.

4.2. Secrets Management Lifecycle
Generation: Terraform creates a random, high-entropy password for the RDS database during provisioning.

Storage: The complete database credentials are stored as a secret in AWS Secrets Manager.

Access Control: The application's IRSA role is granted a least-privilege policy that only allows it to read this specific secret.

Consumption: At runtime, the AWS Secrets and Configuration Provider (ASCP) mounts the secret as files into the pod's filesystem. The application reads credentials from these files, ensuring they are never exposed as environment variables or baked into the container image.

4.3. Integrated Security Scanning (SCA, SAST, DAST)
The pipeline includes a comprehensive, automated security scanning toolchain to identify vulnerabilities early and often.

Software Composition Analysis (SCA): The dependency_review job scans pull requests for known vulnerabilities in open-source libraries. Additionally, the trivy scan in the build job re-validates application dependencies within the final container image.

Static Application Security Testing (SAST): The Trivy scan also inspects the container image's operating system and configuration for known CVEs, acting as a SAST tool for the infrastructure layer of the image. The iac_scan job provides SAST for the Terraform and Helm code itself.

Dynamic Application Security Testing (DAST): The OWASP ZAP scan runs against the deployed application in the staging environment. This "outside-in" scan actively probes the application for runtime vulnerabilities such as Cross-Site Scripting (XSS), SQL Injection, and insecure configurations.

5. Operational Guide
5.1. Prerequisites
A one-time setup is required for the target AWS account and EKS cluster:

Terraform State Backend: An S3 bucket and DynamoDB table must be created to store the Terraform state remotely and securely.

VPC Peering: An active VPC Peering Connection must exist between the EKS VPC and the Database VPC, with correctly configured route tables.

EKS IAM OIDC Provider: The EKS cluster must have an associated IAM OIDC provider.

ASCP Add-on: The aws-secrets-store-csi-driver EKS add-on must be installed and active.

GitHub Configuration: The required secrets (AWS_CI_ROLE_ARN, DOCKERHUB_USERNAME, DOCKERHUB_TOKEN) and variables (AWS_REGION, EKS_CLUSTER_NAME, TF_STATE_BUCKET, TF_STATE_DYNAMODB_TABLE) must be configured in the repository settings.

5.2. Deployment Process
The pipeline is entirely driven by git operations:

Deploy to Development: Push or merge a commit to the dev branch.

Deploy to Staging: Push or merge a commit to the staging branch.

Deploy to Production: Push or merge a commit to the main branch.

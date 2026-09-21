# Stage 0: Platform Infrastructure CI/CD Pipeline (Bootstrap)

This stage provisions the foundational CI/CD pipeline for the **Platform Infrastructure** using `modules/secure-cicd-pipeline`.

It creates the Cloud Storage state bucket, KMS encryption keys, and Cloud Build triggers linked to the platform infrastructure repository (`1-platform`), enabling GitOps automation for network and GKE cluster provisioning.

## Persona
- **Platform Admin / Foundation Team**

## Responsibilities
- Provision Cloud Storage bucket for Terraform state management.
- Configure Cloud Build triggers for `1-platform` Terraform code (`cloudbuild-tf-plan.yaml` and `cloudbuild-tf-apply.yaml`).
- Assign least-privilege IAM roles to the Cloud Build Service Account across `network_project_id` and `cluster_project_id`.

## Usage
1. Copy the sample variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Update `terraform.tfvars` with your project IDs and repository secrets.
3. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```

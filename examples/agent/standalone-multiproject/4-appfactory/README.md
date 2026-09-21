# Stage 4: Application Factory & Infra Pipeline (App Factory)

This stage provisions the tenant infrastructure environment and the CI/CD pipeline for the **Application Infrastructure** using `modules/secure-cicd-pipeline`.

It creates the state bucket for `5-appinfra`, the Artifact Registry repository, and the Cloud Build triggers that build and apply the application infrastructure (`5-appinfra`).

## Persona
- **Platform Team / App Admin Lead**

## Responsibilities
- Provision Cloud Storage bucket for `5-appinfra` Terraform state management.
- Provision Artifact Registry repository for Capital Agent container images.
- Configure Cloud Build triggers for `5-appinfra` Terraform code (`cloudbuild-tf-plan.yaml` and `cloudbuild-tf-apply.yaml`).
- Grant least-privilege IAM roles to the Cloud Build Service Account across `app_admin_project_id` and `workload_project_id`.

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

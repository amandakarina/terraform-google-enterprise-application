# Stage 5: Application Infrastructure & Delivery Pipeline (App Infra)

This stage provisions the workload infrastructure backing resources and the application delivery pipeline for the Capital Agent.

It creates the Cloud Deploy delivery pipeline (`modules/deployment-pipeline`), the Google Service Account (`gsa-capital-agent`), the IAM roles for Vertex AI Gemini API access (`roles/aiplatform.user`), and the Kubernetes Workload Identity binding.

## Persona
- **App Infra Team / DevOps Engineer**

## Responsibilities
- Provision Cloud Deploy delivery pipeline and targets pointing to the GKE cluster.
- Configure Cloud Build trigger for the `6-appsource` code repository.
- Provision Google Service Account (`gsa-capital-agent`) in `workload_project_id`.
- Bind `roles/aiplatform.user` and `roles/cloudtrace.agent` to the GSA.
- Establish Workload Identity binding between `capital-agent-ksa` and `gsa-capital-agent`.

## Usage
1. Copy the sample variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Populate `cluster_membership_ids` and `cluster_service_accounts` from `1-platform`.
3. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```

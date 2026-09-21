/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  application_name       = "agent"
  service_name           = "capital-agent"
  team_name              = "agent"
  cluster_membership_ids = { (var.env) : { "cluster_membership_ids" : var.cluster_membership_ids } }
}

# 1. Cloud Deploy Delivery Pipeline & Application Trigger
module "cicd" {
  source   = "../../../../modules/deployment-pipeline"
  for_each = var.cloudbuildv2_repository_config.repositories

  project_id                 = var.app_admin_project_id
  region                     = var.region
  env_cluster_membership_ids = local.cluster_membership_ids
  cluster_service_accounts   = { for i, sa in var.cluster_service_accounts : (i) => "serviceAccount:${sa}" }

  service_name           = local.service_name
  team_name              = local.team_name
  repo_name              = each.value.repository_name
  repo_branch            = "main"
  app_build_trigger_yaml = "cloudbuild.yaml"

  additional_substitutions = {
    _SERVICE = local.service_name
    _TEAM    = local.team_name
  }

  ci_build_included_files = ["*"]
  buckets_force_destroy   = true

  cloudbuildv2_repository_config = var.cloudbuildv2_repository_config

  private_workerpool = {
    use_private_workerpool = var.workerpool_id != null
    private_workerpool_id  = var.workerpool_id
  }

  logging_bucket = var.logging_bucket
  bucket_kms_key = var.bucket_kms_key

  attestation_kms_key = var.attestation_kms_key
  attestor_id         = var.attestor_id

  binary_authorization_image         = var.binary_authorization_image
  binary_authorization_repository_id = var.binary_authorization_repository_id
}

# 2. Google Service Account for Capital Agent Workload
resource "google_service_account" "gsa_capital_agent" {
  project      = var.workload_project_id
  account_id   = "gsa-capital-agent"
  display_name = "GSA for Capital Agent"
}

# 3. IAM: Vertex AI and Cloud Trace Permissions on Workload Project
resource "google_project_iam_member" "gsa_vertex_user" {
  project = var.workload_project_id
  role    = "roles/aiplatform.user"
  member  = google_service_account.gsa_capital_agent.member
}

resource "google_project_iam_member" "gsa_trace_agent" {
  project = var.workload_project_id
  role    = "roles/cloudtrace.agent"
  member  = google_service_account.gsa_capital_agent.member
}

# 4. Workload Identity Federation (KSA -> GSA)
resource "google_service_account_iam_member" "wi_binding" {
  service_account_id = google_service_account.gsa_capital_agent.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.cluster_project_id}.svc.id.goog[capital-agent-${var.env}/capital-agent-ksa]"
}

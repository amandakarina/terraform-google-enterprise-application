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

output "tf_state_bucket" {
  description = "Cloud Storage bucket for Application Infrastructure Terraform state."
  value       = module.appinfra_tf_state_bucket.name
}

output "cloudbuild_service_account" {
  description = "Service account used by Cloud Build to deploy application infrastructure."
  value       = { for k, v in module.app_cicd : k => v.cloudbuild_sa }
}

output "artifact_registry_repository" {
  description = "Artifact registry repository ID for Capital Agent container images."
  value       = { for k, v in module.app_cicd : k => v.artifact_registry_repository_id }
}

output "app_admin_project_id" {
  description = "Application Admin CI/CD project ID."
  value       = { for k, v in module.app_cicd : k => v.app_admin_project_id }
}

output "app_infra_project_ids" {
  description = "Application environment infrastructure project IDs."
  value       = { for k, v in module.app_cicd : k => v.app_infra_project_ids }
}

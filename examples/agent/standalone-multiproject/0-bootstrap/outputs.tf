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
  description = "Cloud Storage bucket for Platform Infrastructure Terraform state."
  value       = module.platform_tf_state_bucket.name
}

output "cloudbuild_service_account" {
  description = "Service account used by Cloud Build to deploy platform infrastructure."
  value       = { for k, v in module.platform_cicd : k => v.cloudbuild_sa }
}

output "artifact_registry_repository" {
  description = "Artifact registry repository ID."
  value       = { for k, v in module.platform_cicd : k => v.artifact_registry_repository_id }
}

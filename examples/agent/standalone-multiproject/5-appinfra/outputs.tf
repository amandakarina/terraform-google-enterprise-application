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

output "gsa_email" {
  description = "The email of the Google Service Account created for Capital Agent."
  value       = google_service_account.gsa_capital_agent.email
}

output "delivery_pipeline_name" {
  description = "The Cloud Deploy delivery pipeline name."
  value       = { for k, v in module.cicd : k => v.delivery_pipeline_name }
}

output "cloudbuild_service_account" {
  description = "The Cloud Build service account used for application container builds."
  value       = { for k, v in module.cicd : k => v.cloudbuild_service_account }
}

output "app_admin_project_id" {
  description = "The GCP project ID hosting the CI/CD pipeline."
  value       = var.app_admin_project_id
}

output "workload_project_id" {
  description = "The GCP project ID hosting workload services."
  value       = var.workload_project_id
}

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

variable "app_admin_project_id" {
  description = "The GCP Project ID where the tenant admin CI/CD pipeline, Private Worker Pool, and Artifact Registry reside."
  type        = string
}

variable "workload_project_id" {
  description = "The GCP Project ID where application backing services, GSAs, and Vertex AI resources reside."
  type        = string
}

variable "cluster_project_id" {
  description = "The GCP Project ID hosting the GKE cluster (used for Workload Identity binding)."
  type        = string
}

variable "region" {
  description = "The Google Cloud region for deployment resources."
  type        = string
  default     = "us-central1"
}

variable "env" {
  description = "The deployment environment name (e.g. development, nonproduction, production)."
  type        = string
  default     = "development"
}

variable "cluster_membership_ids" {
  description = "List of GKE cluster membership IDs obtained from the 1-platform stage."
  type        = list(string)
}

variable "cluster_service_accounts" {
  description = "List of GKE cluster service accounts obtained from the 1-platform stage."
  type        = list(string)
}

variable "attestor_id" {
  description = "The Binary Authorization attestor ID from the 1-platform stage."
  type        = string
  default     = null
}

variable "cloudbuildv2_repository_config" {
  description = "Cloud Build v2 repository connection configuration for 6-appsource application code."
  type        = any
  default = {
    repo_type = "GITLABv2"
    repositories = {
      capital-agent = {
        repository_name = "eab-agent-capital-agent"
        repository_url  = "https://gitlab.com/user/eab-agent-capital-agent.git"
      }
    }
    gitlab_authorizer_credential_secret_id      = "REPLACE_WITH_READ_API_SECRET_ID"
    gitlab_read_authorizer_credential_secret_id = "REPLACE_WITH_READ_USER_SECRET_ID"
    gitlab_webhook_secret_id                    = "REPLACE_WITH_WEBHOOK_SECRET_ID"
    gitlab_enterprise_host_uri                  = "https://gitlab.com"
    gitlab_enterprise_service_directory         = "REPLACE_WITH_SERVICE_DIRECTORY"
    gitlab_enterprise_ca_certificate            = "REPLACE_WITH_SSL_CERT"
    secret_project_id                           = "REPLACE_WITH_SECRET_PROJECT_ID"
  }
}

variable "workerpool_id" {
  description = "The ID of the Cloud Build private worker pool if pre-created."
  type        = string
  default     = null
}

variable "logging_bucket" {
  description = "Logging bucket name for CI/CD logs."
  type        = string
  default     = null
}

variable "bucket_kms_key" {
  description = "KMS key ID for Cloud Storage bucket encryption."
  type        = string
  default     = null
}

variable "attestation_kms_key" {
  description = "KMS key ID for Binary Authorization image attestation."
  type        = string
  default     = null
}

variable "binary_authorization_image" {
  description = "Container image used for Binary Authorization attestor."
  type        = string
  default     = null
}

variable "binary_authorization_repository_id" {
  description = "Artifact Registry repository ID for Binary Authorization."
  type        = string
  default     = null
}

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

variable "create_admin_project" {
  description = "Whether to create a dedicated GCP project for tenant CI/CD admin."
  type        = bool
  default     = true
}

variable "app_admin_project_id" {
  description = "The GCP Project ID where the tenant admin CI/CD pipeline resides (if not creating project)."
  type        = string
  default     = null
}

variable "create_infra_project" {
  description = "Whether to create dedicated GCP projects for application workload infrastructure per environment."
  type        = bool
  default     = true
}

variable "org_id" {
  description = "The GCP Organization ID."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "The GCP Folder ID where projects will be created."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "The GCP Billing Account ID."
  type        = string
  default     = null
}

variable "workload_project_id" {
  description = "The GCP Project ID where application backing services reside (if not creating project)."
  type        = string
  default     = null
}

variable "cluster_project_id" {
  description = "The GCP Project ID hosting the GKE cluster."
  type        = string
}

variable "region" {
  description = "The Google Cloud region for deployment resources."
  type        = string
  default     = "us-central1"
}

variable "envs" {
  description = "Environments configuration map for application infrastructure."
  type = map(object({
    billing_account    = optional(string)
    folder_id          = optional(string)
    network_project_id = optional(string)
    network_self_link  = optional(string, "")
    org_id             = optional(string)
    subnets_self_links = optional(list(string), [])
  }))
  default = {
    development = {}
  }
}

variable "cloudbuildv2_repository_config" {
  description = "Cloud Build v2 repository connection configuration for App Infra pipeline."
  type        = any
  default = {
    repo_type = "GITLABv2"
    repositories = {
      capital-agent = {
        repository_name = "capital-agent-i-r"
        repository_url  = "https://gitlab.com/user/capital-agent-i-r.git"
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

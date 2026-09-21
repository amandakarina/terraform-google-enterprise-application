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

variable "bootstrap_project_id" {
  description = "The GCP Project ID where the platform CI/CD pipeline triggers and state bucket reside."
  type        = string
}

variable "network_project_id" {
  description = "The GCP Project ID where the network infrastructure will be provisioned."
  type        = string
}

variable "cluster_project_id" {
  description = "The GCP Project ID where the GKE cluster will be provisioned."
  type        = string
}

variable "region" {
  description = "The Google Cloud region for CI/CD resources."
  type        = string
  default     = "us-central1"
}

variable "envs" {
  description = "Environments configuration map for platform infrastructure."
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
  description = "Cloud Build v2 repository connection configuration for platform infrastructure."
  type        = any
  default = {
    repo_type = "GITLABv2"
    repositories = {
      platform-infra = {
        repository_name = "eab-platform-infra"
        repository_url  = "https://gitlab.com/user/eab-platform-infra.git"
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

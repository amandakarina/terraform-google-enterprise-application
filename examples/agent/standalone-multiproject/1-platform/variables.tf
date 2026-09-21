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

variable "network_project_id" {
  description = "The GCP Project ID where the cluster network and Shared VPC will be created."
  type        = string
}

variable "cluster_project_id" {
  description = "The GCP Project ID where the GKE cluster and Fleet will be created (if create_cluster_project is false)."
  type        = string
  default     = null
}

variable "create_cluster_project" {
  description = "Whether to create a dedicated GCP project for the GKE cluster."
  type        = bool
  default     = true
}

variable "org_id" {
  description = "The GCP Organization ID."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "The GCP Folder ID where the project will be created."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "The GCP Billing Account ID."
  type        = string
  default     = null
}

variable "region" {
  description = "The Google Cloud region for the cluster and network resources."
  type        = string
  default     = "us-central1"
}

variable "env" {
  description = "The deployment environment name (e.g. development, nonproduction, production)."
  type        = string
  default     = "development"
}

variable "cluster_type" {
  description = "The GKE cluster type (AUTOPILOT, STANDARD, STANDARD-NAP)."
  type        = string
  default     = "AUTOPILOT"
}

variable "cluster_prefix" {
  description = "Prefix for GKE cluster naming."
  type        = string
  default     = "ag"
}

variable "vpc_name" {
  description = "The VPC network name prefix."
  type        = string
  default     = "cap-agent-cluster"
}

variable "teams" {
  description = "Team namespaces to configure in the GKE Fleet scope."
  type        = map(string)
  default = {
    "capital-agent" = ""
  }
}

variable "ncc_config" {
  description = <<-EOT
    Configuration block for Google Cloud Network Connectivity Center (NCC) Spokes.
    - enable_ncc: (bool) Toggles whether to create a new NCC spoke (default: true).
    - hub_uri: (string) The URI of an existing Hub. [Required if enable_ncc is TRUE]
    - spoke_group: (string) The NCC group the spoke belongs to (default: "default").
    - spoke_name: (string) Name for the main VPC spoke.
    - spoke_description: (string) Description for the main VPC spoke.
    - spoke_labels: (map) Labels for the main VPC spoke.
    - spoke_exclude_export_ranges: (set of strings) IP ranges to exclude from route export.
    - spoke_include_export_ranges: (set of strings) IP ranges to explicitly include in route export.
  EOT
  type = object({
    enable_ncc                  = optional(bool, true)
    hub_uri                     = optional(string)
    spoke_group                 = optional(string, "default")
    spoke_name                  = optional(string, "vpc-spoke-agent")
    spoke_description           = optional(string, "NCC Spoke for Capital Agent cluster network")
    spoke_labels                = optional(map(string), {})
    spoke_exclude_export_ranges = optional(set(string), [])
    spoke_include_export_ranges = optional(set(string), [])
  })
  default = {
    enable_ncc = false
  }
}

variable "service_perimeter_mode" {
  description = "VPC-SC perimeter mode ('OFF', 'DRY_RUN', 'ENFORCE')."
  type        = string
  default     = "OFF"
}

variable "service_perimeter_name" {
  description = "Name of the VPC-SC access perimeter if applicable."
  type        = string
  default     = null
}

variable "access_level_name" {
  description = "Access context manager access level name."
  type        = string
  default     = null
}

variable "logging_bucket" {
  description = "Logging bucket name for cluster audit logs."
  type        = string
  default     = null
}

variable "bucket_kms_key" {
  description = "KMS key ID for bucket encryption."
  type        = string
  default     = null
}

variable "attestation_kms_key" {
  description = "KMS key ID for Binary Authorization attestor."
  type        = string
  default     = null
}

variable "config_sync_repository_url" {
  description = "Git repository URL for Config Sync."
  type        = string
  default     = "https://gitlab.com/user/config-sync-development.git"
}

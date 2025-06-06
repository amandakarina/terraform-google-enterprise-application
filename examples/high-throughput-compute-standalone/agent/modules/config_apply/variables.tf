# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#
# Mandatory configuration
#

# Project ID where resources will be deployed
variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created."
}

# Region where the build and artifact repository is
variable "region" {
  type        = string
  description = "The Region of the build"
}

variable "cluster_name" {
  type        = string
  description = "Cluster Name"
}

# Containers to build
variable "agent_image" {
  type        = string
  description = "Agent image for Cloud Run templates"
}

# Containers to build
variable "workload_image" {
  type        = string
  description = "Map of image name to configuration (source)"
}

# Sidecar configuration
variable "workload_grpc_endpoint" {
  type        = string
  description = "Workload GRPC Endpoint for Sidecar Configuration."
}

variable "workload_args" {
  type        = list(string)
  description = "Workload image for Cloud Run templates"
}

variable "gcs_bucket" {
  type        = string
  description = "The name of the Google Cloud Storage (GCS) bucket used"
}

variable "pubsub_hpa_request" {
  type        = string
  description = "The name of the Pub/Sub subscription"
}

variable "pubsub_job_request" {
  type        = string
  description = "The name of the Pub/Sub subscription"
}


#
# Optional functionality
# (Review suggested)
#

# Configurations to create shell scripts for
variable "test_configs" {
  type = map(object({
    parallel = number
    testfile = string
  }))
  default     = {}
  description = "Test configurations (parallel = 0 use autoscaler)"
}

variable "workload_init_args" {
  type        = list(list(string))
  default     = []
  description = "Workload initialization arguments to run"
}

#
# Naming defaults
# (Only change if conflicting with other modules)
#

variable "gke_job_request" {
  type        = string
  default     = "gke_job_request"
  description = "The identifier for the GKE job request. Default is 'gke_job_request'."
}

variable "gke_job_response" {
  type        = string
  default     = "gke_job_response"
  description = "The identifier for the GKE job response. Default is 'gke_job_response'."
}

variable "gke_hpa_request" {
  type        = string
  default     = "gke_hpa_request"
  description = "The identifier for the GKE HPA request. Default is 'gke_hpa_request'."
}

variable "gke_hpa_response" {
  type        = string
  default     = "gke_hpa_response"
  description = "The identifier for the GKE HPA response. Default is 'gke_hpa_response'."
}

# Parallelstore
# Enable/disable Parallelstore deployment (default: false)
variable "parallelstore_enabled" {
  type        = bool
  description = "Enable or disable the deployment of Parallelstore."
  default     = false
}

variable "parallelstore_access_points" {
  type        = string
  default     = null
  description = "Access points for the parallel store. Must be provided if parallelstore_enabled is true."
  # validation {
  #   condition     = var.parallelstore_enabled ? var.parallelstore_access_points != null : true
  #   error_message = "parallelstore_access_points must be set when parallelstore_enabled is true."
  # }
}

variable "parallelstore_vpc_name" {
  type        = string
  default     = null
  description = "Name of the VPC associated with the parallel store. Required when parallelstore_enabled is true."
  # validation {
  #   condition     = var.parallelstore_enabled ? var.parallelstore_vpc_name != null : true
  #   error_message = "parallelstore_vpc_name must be set when parallelstore_enabled is true."
  # }
}

variable "parallelstore_location" {
  type        = string
  default     = null
  description = "Location of the parallel store. Mandatory if parallelstore_enabled is true."
  # validation {
  #   condition     = var.parallelstore_enabled ? var.parallelstore_location != null : true
  #   error_message = "parallelstore_location must be set when parallelstore_enabled is true."
  # }
}

variable "parallelstore_instance_name" {
  type        = string
  default     = null
  description = "Name of the parallel store instance. Must be specified when parallelstore_enabled is true."
  # validation {
  #   condition     = var.parallelstore_enabled ? var.parallelstore_instance_name != null : true
  #   error_message = "parallelstore_instance_name must be set when parallelstore_enabled is true."
  # }
}

variable "parallelstore_capacity_gib" {
  type        = number
  default     = null
  description = "Capacity of the parallel store in GiB. Required if parallelstore_enabled is true."
  # validation {
  #   condition     = var.parallelstore_enabled ? var.parallelstore_capacity_gib != null : true
  #   error_message = "parallelstore_capacity_gib must be set when parallelstore_enabled is true."
  # }
}


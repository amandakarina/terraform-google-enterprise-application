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

output "network_name" {
  description = "The name of the VPC network created."
  value       = module.network.network_name
}

output "network_self_link" {
  description = "The URI of the VPC network created."
  value       = module.network.network_self_link
}

output "subnets" {
  description = "The subnets created within the cluster network."
  value       = module.network.subnets
}

output "cluster_membership_ids" {
  description = "GKE Fleet Membership IDs of the created clusters."
  value       = module.multitenant_infra.cluster_membership_ids
}

output "cluster_service_accounts" {
  description = "Service accounts associated with the cluster node pools."
  value       = module.multitenant_infra.cluster_service_accounts
}

output "cluster_project_id" {
  description = "The GCP project ID hosting the GKE cluster and Fleet."
  value       = module.multitenant_infra.cluster_project_id
}

output "network_project_id" {
  description = "The GCP project ID hosting the VPC network."
  value       = var.network_project_id
}

output "attestor_id" {
  description = "The Binary Authorization attestor ID if attestation key is configured."
  value       = module.fleetscope_infra.attestor_id
}

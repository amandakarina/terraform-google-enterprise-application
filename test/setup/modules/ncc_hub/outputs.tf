/**
 * Copyright 2024 Google LLC
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

output "hub_network" {
  value       = module.hub.network
  description = "The created network"
}

output "hub_subnets" {
  value       = module.hub.subnets
  description = "A map with keys of form subnet_region/subnet_name and values being the outputs of the google_compute_subnetwork resources used to create corresponding subnets."
}

output "hub_network_name" {
  value       = module.hub.network_name
  description = "The name of the VPC being created"
}

output "project_id_hub" {
  value       = module.hub.project_id
  description = "VPC project id"
}

output "hub_dns_policy" {
  value       = module.hub.dns_policy
  description = "The name of the DNS policy being created"
}

output "hub_network_self_link" {
  value       = module.hub.network_self_link
  description = "The URI of the VPC being created"
}

output "hub_subnets_names" {
  value       = module.hub.subnets_names
  description = "The names of the subnets being created"
}

output "hub_subnets_ips" {
  value       = module.hub.subnets_ips
  description = "The IPs and CIDRs of the subnets being created"
}

output "hub_subnets_self_links" {
  value       = module.hub.subnets_self_links
  description = "The self-links of subnets being created"
}

output "hub_subnets_regions" {
  value       = module.hub.subnets_regions
  description = "The region where the subnets will be created"
}

output "hub_subnets_secondary_ranges" {
  value       = module.hub.subnets_secondary_ranges
  description = "The secondary ranges associated with these subnets"
}

output "hub_firewall_policy" {
  value       = module.hub.firewall_policy
  description = "Policy created for firewall policy rules."
}

output "ncc_hub_uri" {
  value       = module.hub.ncc_hub_uri
  description = "The NCC Hub ID"
}

output "hub_subnets_private_access" {
  value       = module.hub.subnets_private_access
  description = "Whether the subnets will have access to Google API's without a public IP"
}

output "hub_subnets_flow_logs" {
  value       = module.hub.subnets_flow_logs
  description = "Whether the subnets will have VPC flow logs enabled"
}

output "hub_route_names" {
  value       = module.hub.route_names
  description = "The route names associated with this VPC"
}

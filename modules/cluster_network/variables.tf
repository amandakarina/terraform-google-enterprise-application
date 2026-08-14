/**
 * Copyright 2025 Google LLC
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

variable "vpc_name" {
  description = "The VPC name to be concat with `vpc-` prefix."
  type        = string
}

variable "project_id" {
  description = "The project to deploy in"
  type        = string
}

variable "region" {
  description = "The region where NAT will be created"
  type        = string
}

variable "subnets" {
  description = "Sub-networks to be created."
  type        = any
}

variable "secondary_ranges" {
  description = "Secondary ranges that will be used in some of the subnets."
  type        = any
  default     = {}
}

variable "ingress_rules" {
  description = "List of ingress rules. This will be ignored if variable 'rules' is non-empty."
  type        = any
  default     = []
}

variable "egress_rules" {
  description = "List of egress rules. This will be ignored if variable 'rules' is non-empty"
  type        = any
  default     = []
}

variable "ncc_hub_uri" {
  description = "The NCC Hub ID"
  type        = string
}

variable "hub_network_name" {
  description = "The name of the VPC being created"
  type        = string
}

variable "nat_config" {
  description = <<-EOT
    Configuration for Cloud NAT and underlying Cloud Routers.
    Attributes:
    - enabled: Set to true to create NAT resources. If false, no routers or NAT IPs are provisioned (default: false).
    - egress_tags: Network tags used for routing internet egress traffic (default: ["egress-internet"]).
    - bgp_asn: The BGP Autonomous System Number assigned to the Cloud Router (default: 64512).
    - regions: Defines which regions get a NAT router.
      - name: The GCP region name (e.g., "us-central1") where the router and NAT will be deployed.
      - num_addresses: The number of static external IP addresses to manually allocate and assign to the NAT gateway in this region (default: 2).
  EOT
  type = object({
    enabled     = optional(bool, false)
    egress_tags = optional(list(string), ["egress-internet"])
    bgp_asn     = optional(number, 64512)
    regions = optional(list(object({
      name          = string
      num_addresses = optional(number, 2)
    })))
  })
  default = {}
}

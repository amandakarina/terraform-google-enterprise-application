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

locals {
  apps = {
    "capital-agent" : {
      "acronym"          = "ag",
      "ip_address_names" = [],
      "certificates"     = {},
    }
  }

  subnets = [
    {
      subnet_name           = "sb-gke-${var.region}"
      subnet_ip             = "10.0.0.0/24"
      subnet_region         = var.region
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "Subnet for GKE cluster nodes"
    },
    {
      subnet_name   = "sb-proxy-${var.region}"
      subnet_ip     = "10.128.0.0/23"
      subnet_region = var.region
      purpose       = "REGIONAL_MANAGED_PROXY"
      role          = "ACTIVE"
      description   = "Regional proxy-only subnet for Gateway API"
    }
  ]

  secondary_ranges = {
    "sb-gke-${var.region}" = [
      {
        range_name    = "rn-sb-gke-${var.region}-pods"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "rn-sb-gke-${var.region}-services"
        ip_cidr_range = "10.2.0.0/20"
      }
    ]
  }
}

# 1. Cluster Network with NCC Spoke
module "network" {
  source = "../../../../modules/cluster_network"

  project_id       = var.network_project_id
  vpc_name         = var.vpc_name
  shared_vpc_host  = var.create_cluster_project || (var.cluster_project_id != null && var.network_project_id != var.cluster_project_id)
  subnets          = local.subnets
  secondary_ranges = local.secondary_ranges
  ncc_config       = var.ncc_config
}

# Attach service project to Shared VPC if projects are separated and not created by modules/gke
resource "google_compute_shared_vpc_service_project" "service_project_attachment" {
  count           = !var.create_cluster_project && var.cluster_project_id != null && var.network_project_id != var.cluster_project_id ? 1 : 0
  host_project    = var.network_project_id
  service_project = var.cluster_project_id

  depends_on = [module.network]
}

# 2. Multi-tenant Private GKE Cluster
module "multitenant_infra" {
  source = "../../../../modules/gke"

  apps                   = local.apps
  cluster_subnetworks    = [for i, j in module.network.subnets : j.self_link if !strcontains(i, "proxy")]
  network_project_id     = var.network_project_id
  cluster_project_id     = var.cluster_project_id
  env                    = var.env
  cluster_type           = var.cluster_type
  cluster_prefix         = var.cluster_prefix
  create_cluster_project = var.create_cluster_project
  org_id                 = var.org_id
  folder_id              = var.folder_id
  billing_account        = var.billing_account

  service_perimeter_name = var.service_perimeter_name
  service_perimeter_mode = var.service_perimeter_mode
  access_level_name      = var.access_level_name
  deletion_protection    = false

  depends_on = [
    module.network,
    google_compute_shared_vpc_service_project.service_project_attachment
  ]
}

# 3. GKE Fleet Scope & Governance
module "fleetscope_infra" {
  source = "../../../../modules/fleetscope"

  env                        = var.env
  cluster_project_id         = module.multitenant_infra.cluster_project_id
  network_project_id         = var.network_project_id
  fleet_project_id           = module.multitenant_infra.cluster_project_id
  namespace_ids              = var.teams
  cluster_membership_ids     = module.multitenant_infra.cluster_membership_ids
  config_sync_secret_type    = "token"
  config_sync_repository_url = var.config_sync_repository_url
  cluster_service_accounts   = values(module.multitenant_infra.cluster_service_accounts)
  attestation_kms_key        = var.attestation_kms_key

  depends_on = [module.multitenant_infra]
}

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
  default_region1 = "us-central1"
  default_region2 = "us-west1"

  private_service_cidr_hub   = "10.16.40.0/21"
  private_service_connect_ip = "10.17.0.5"

  subnet_primary_ranges_hub = {
    (local.default_region1) = "10.8.0.0/18"
    (local.default_region2) = "10.9.0.0/18"
  }

  subnet_proxy_ranges_hub = {
    (local.default_region1) = "10.26.0.0/23"
    (local.default_region2) = "10.27.0.0/23"
  }

  private_service_cidr_spoke       = "10.16.56.0/21"
  private_service_connect_ip_spoke = "10.17.0.8"

  subnet_primary_ranges_spoke = {
    (local.default_region1) = "10.8.192.0/18"
    (local.default_region2) = "10.9.192.0/18"
  }

  subnet_proxy_ranges_spoke = {
    (local.default_region1) = "10.26.6.0/23"
    (local.default_region2) = "10.27.6.0/23"
  }

  secondary_ranges_spoke = {
    (local.default_region1) = [
      {
        range_name    = "rn-s-svpc-${local.default_region1}-gke-pod"
        ip_cidr_range = "100.72.192.0/18"
      },
      {
        range_name    = "rn-s-svpc-${local.default_region1}-gke-svc"
        ip_cidr_range = "100.73.192.0/18"
      }
    ]
  }
}


module "hub" {
  source = "git::https://github.com/daniel-cit/terraform-google-network.git//modules/foundation/network?ref=ncc-and-peering-changes"
  # source = "../../modules/foundation/network"

  project_id                      = var.project_id_hub
  vpc_name                        = var.network_name_hub
  private_service_connect_ip      = local.private_service_connect_ip
  private_service_cidr            = local.private_service_cidr_hub
  enable_all_vpc_internal_traffic = false
  shared_vpc_host                 = false

  resource_codes = {
    short = "h"
    long  = "hub"
  }

  dns_config = {
    onprem_forwarding = true
    type              = "hub"
    domain            = "example.com."
    target_name_server_addresses = [ // See https://cloud.google.com/dns/docs/overview#dns-forwarding-zones
      {
        ipv4_address    = "192.168.0.1",
        forwarding_path = "default"
      },
      {
        ipv4_address    = "192.168.0.2",
        forwarding_path = "default"
      }
    ]
  }

  ncc_hub_config = {
    create_hub                  = true
    description                 = "hub"
    export_psc                  = true
    name                        = "hub"
    preset_topology             = "STAR"
    spoke_group                 = "center"
    auto_accept_projects_center = [var.project_id_hub]
    auto_accept_projects_edge   = var.auto_accept_projects_edge

    hub_labels = {
      type = "hub"
    }
    spoke_labels = {
      type = "hub_vpc"
    }

  }

  subnets = [
    {
      subnet_name   = "sb-h-svpc-${local.default_region1}"
      subnet_ip     = local.subnet_primary_ranges_hub[local.default_region1]
      subnet_region = local.default_region1
      description   = "Network subnet for ${local.default_region1}"
    },
    {
      subnet_name   = "sb-h-svpc-${local.default_region2}"
      subnet_ip     = local.subnet_primary_ranges_hub[local.default_region2]
      subnet_region = local.default_region2
      description   = "Network subnet for ${local.default_region2}"
    },
    {
      subnet_name           = "sb-h-svpc-${local.default_region1}-proxy"
      subnet_ip             = local.subnet_proxy_ranges_hub[local.default_region1]
      subnet_region         = local.default_region1
      subnet_flow_logs      = false
      subnet_private_access = false
      description           = "Network proxy-only subnet for ${local.default_region1}"
      role                  = "ACTIVE"
      purpose               = "REGIONAL_MANAGED_PROXY"
    },
    {
      subnet_name           = "sb-h-svpc-${local.default_region2}-proxy"
      subnet_ip             = local.subnet_proxy_ranges_hub[local.default_region2]
      subnet_region         = local.default_region2
      subnet_flow_logs      = false
      subnet_private_access = false
      description           = "Network proxy-only subnet for ${local.default_region2}"
      role                  = "ACTIVE"
      purpose               = "REGIONAL_MANAGED_PROXY"
    }
  ]
  secondary_ranges = {}

  nat_config = {
    enabled = true
    regions = [
      {
        name          = local.default_region1,
        num_addresses = 2
      },
      {
        name          = local.default_region2,
        num_addresses = 2
      }
    ]
  }
}

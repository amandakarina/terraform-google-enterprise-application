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

locals {
  private_service_cidr_spoke       = "10.16.56.0/21"
  private_service_connect_ip_spoke = "10.17.0.8"
}

module "spoke" {
  source = "git::https://github.com/daniel-cit/terraform-google-network.git//modules/foundation/network?ref=ncc-and-peering-changes"

  project_id                      = var.project_id
  vpc_name                        = var.vpc_name
  private_service_connect_ip      = local.private_service_connect_ip_spoke
  private_service_cidr            = local.private_service_cidr_spoke
  enable_all_vpc_internal_traffic = true
  shared_vpc_host                 = false

  resource_code = "s"
  dns_config = {
    dns_hub_project_id   = var.project_id
    dns_hub_network_name = var.hub_network_name
    type                 = "spoke"
  }

  ncc_hub_config = {
    create_hub  = false
    export_psc  = true
    spoke_group = "edge"
    uri         = var.ncc_hub_uri

    hub_labels = {
      type = "spoke"
    }
    spoke_labels = {
      type = "spoke_vpc"
    }
  }

  nat_config = var.nat_config

  subnets          = var.subnets
  secondary_ranges = var.secondary_ranges

}

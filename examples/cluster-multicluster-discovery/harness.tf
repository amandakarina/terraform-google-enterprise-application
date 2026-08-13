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

data "google_project" "project" {
  project_id = var.project_id
}

module "cluster_network" {
  source = "../../modules/cluster_network"

  vpc_name   = "vpc-eab-cluster"
  project_id = var.project_id
  region     = var.regions[0]
  subnets = [for i, region in var.regions :
    {
      subnet_name           = "eab-cluster-net-${region}"
      subnet_ip             = cidrsubnet(var.base_cidr, 8, i)
      subnet_region         = region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    for i, region in var.regions :
    "eab-cluster-net-${region}" => [
      {
        range_name    = "eab-cluster-net-${region}-secondary-01"
        ip_cidr_range = cidrsubnet(var.pods_base_cidr, 2, i)
      },
      {
        range_name    = "eab-cluster-net-${region}-secondary-02"
        ip_cidr_range = cidrsubnet(var.services_base_cidr, 2, i)
      },
    ]
  }
  ncc_hub_uri      = var.ncc_hub_uri
  hub_network_name = var.hub_network_name

}

resource "google_access_context_manager_service_perimeter_egress_policy" "container_egress" {
  count     = var.service_perimeter_mode == "ENFORCE" && var.service_perimeter_name != "" ? 1 : 0
  perimeter = var.service_perimeter_name
  title     = "e-${data.google_project.project.number}-to-projects/398042134881"
  egress_from {
    sources {
      access_level = "*"
    }    
    source_restriction = "SOURCE_RESTRICTION_ENABLED"   
  }
  egress_to {
    resources = ["projects/398042134881"]
    operations {
      service_name = "logging.googleapis.com"
      method_selectors {
        method = "*"
      }
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_access_context_manager_service_perimeter_dry_run_egress_policy" "container_egress" {
  count     = var.service_perimeter_name != "" ? 1 : 0
  perimeter = var.service_perimeter_name
  title     = "e-${data.google_project.project.number}-to-projects/398042134881"
  egress_from {
    sources {
      access_level = "*"
      
    } 
    source_restriction = "SOURCE_RESTRICTION_ENABLED"   
  }
  egress_to {
    resources = ["projects/398042134881"]
    operations {
      service_name = "logging.googleapis.com"
      method_selectors {
        method = "*"
      }
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "time_sleep" "wait_for_perimeter_replication" {
  create_duration = "2m"
  destroy_duration  = "2m"
  depends_on = [
    google_access_context_manager_service_perimeter_dry_run_egress_policy.container_egress,
    google_access_context_manager_service_perimeter_egress_policy.container_egress
  ]
}

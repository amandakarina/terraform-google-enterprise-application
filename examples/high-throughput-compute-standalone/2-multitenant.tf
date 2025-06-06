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

module "infrastructure" {
  source = "./modules/infrastructure"

  # Project and Regional Configuration
  project_id = var.project_id
  regions    = var.regions

  # Network Configuration
  vpc_name         = var.vpc_name
  storage_ip_range = var.storage_ip_range

  # GKE Cluster Configuration
  gke_standard_cluster_name  = var.gke_standard_cluster_name
  clusters_per_region        = var.clusters_per_region
  node_machine_type_ondemand = var.node_machine_type_ondemand
  node_machine_type_spot     = var.node_machine_type_spot
  min_nodes_ondemand         = var.min_nodes_ondemand
  max_nodes_ondemand         = var.max_nodes_ondemand
  min_nodes_spot             = var.min_nodes_spot
  max_nodes_spot             = var.max_nodes_spot

  # Storage Configuration
  storage_type                  = var.storage_type
  storage_capacity_gib          = var.storage_capacity_gib
  storage_locations             = var.storage_locations
  parallelstore_deployment_type = var.deployment_type
  lustre_filesystem             = var.lustre_filesystem
  lustre_gke_support_enabled    = var.lustre_gke_support_enabled

  # Artifact Registry
  artifact_registry_name = var.artifact_registry_name

  # Security Configuration
  cluster_service_account  = var.cluster_service_account
  enable_workload_identity = var.enable_workload_identity

  # CSI Drivers
  enable_csi_parallelstore = var.enable_csi_parallelstore
  enable_csi_gcs_fuse      = var.enable_csi_gcs_fuse

  depends_on = [null_resource.depends_on_vpc_sc_rules]
}

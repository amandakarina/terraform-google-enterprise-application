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

# 1. State bucket for Platform Infrastructure
module "platform_tf_state_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 9.0"

  name          = "bkt-${var.bootstrap_project_id}-platform-state"
  project_id    = var.bootstrap_project_id
  location      = var.region
  force_destroy = true
}

# 2. CI/CD Pipeline for Platform Infrastructure
module "platform_cicd" {
  source   = "../../../../modules/secure-cicd-pipeline"
  for_each = var.cloudbuildv2_repository_config.repositories

  service_name = "platform-infra"
  acronym      = "plt"

  create_admin_project = false
  admin_project_id     = var.bootstrap_project_id
  create_infra_project = false

  cluster_projects_ids = [var.cluster_project_id]

  envs = {
    for k, v in var.envs : k => merge(v, {
      network_project_id = v.network_project_id != null ? v.network_project_id : var.network_project_id
    })
  }

  cloudbuild_sa_roles = {
    for k, v in var.envs : k => {
      roles = [
        "roles/compute.networkAdmin",
        "roles/compute.securityAdmin",
        "roles/container.admin",
        "roles/gkehub.admin",
        "roles/resourcemanager.projectIamAdmin",
        "roles/iam.serviceAccountAdmin",
        "roles/iam.serviceAccountUser",
      ]
    }
  }

  cloudbuildv2_repository_config = var.cloudbuildv2_repository_config
  workerpool_id                  = var.workerpool_id
}


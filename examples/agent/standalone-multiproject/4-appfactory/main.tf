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

# 1. CI/CD Pipeline for Application Infrastructure (App Factory)
module "app_cicd" {
  source   = "../../../../modules/secure-cicd-pipeline"
  for_each = var.cloudbuildv2_repository_config.repositories

  service_name = "capital-agent"
  acronym      = "ag"

  create_admin_project = var.create_admin_project
  admin_project_id     = var.app_admin_project_id
  create_infra_project = var.create_infra_project

  org_id          = var.org_id
  folder_id       = var.folder_id
  billing_account = var.billing_account

  cluster_projects_ids = [var.cluster_project_id]

  envs = {
    for k, v in var.envs : k => merge(v, {
      org_id          = var.org_id
      folder_id       = var.folder_id
      billing_account = var.billing_account
    })
  }

  cloudbuild_sa_roles = {
    for k, v in var.envs : k => {
      roles = [
        "roles/resourcemanager.projectIamAdmin",
        "roles/iam.serviceAccountAdmin",
        "roles/iam.serviceAccountUser",
        "roles/aiplatform.admin",
        "roles/clouddeploy.admin",
        "roles/cloudbuild.builds.editor",
        "roles/artifactregistry.admin",
        "roles/storage.admin",
      ]
    }
  }

  cloudbuildv2_repository_config = var.cloudbuildv2_repository_config
  workerpool_id                  = var.workerpool_id
}

# 2. State bucket for Application Infrastructure
module "appinfra_tf_state_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 9.0"

  name          = "bkt-${module.app_cicd["capital-agent"].app_admin_project_id}-appinfra-state"
  project_id    = module.app_cicd["capital-agent"].app_admin_project_id
  location      = var.region
  force_destroy = true
}


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

// These values are retrieved from the saved terraform state of the execution
// of previous step using the terraform_remote_state data source.
locals {
  cluster_project_id       = data.terraform_remote_state.multitenant.outputs.cluster_project_id
  cluster_service_accounts = data.terraform_remote_state.multitenant.outputs.cluster_service_accounts
  cluster_project_number   = data.terraform_remote_state.multitenant.outputs.cluster_project_number
  app_project_id           = data.terraform_remote_state.appfactory.outputs.app-group["hpc.hpc-team-b"].app_infra_project_ids[local.env]
}

data "terraform_remote_state" "multitenant" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/multi_tenant/${local.env}"
  }
}

data "terraform_remote_state" "bootstrap" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/bootstrap"
  }
}

data "terraform_remote_state" "appfactory" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/appfactory/shared"
  }
}

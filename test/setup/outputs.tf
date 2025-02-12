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

output "project_id" {
  value = local.project_id
}
output "project_number" {
  value = local.project_number
}

output "sa_email" {
  value = google_service_account.int_test[local.index].email
}

output "sa_key" {
  value     = google_service_account_key.int_test.private_key
  sensitive = true
}

output "envs" {
  value = var.single_project ? {} : { for env, vpc in module.vpc : env => {
    org_id             = var.org_id
    folder_id          = module.folders[local.index].ids[env]
    billing_account    = var.billing_account
    network_project_id = vpc.project_id
    network_self_link  = vpc.network_self_link,
    subnets_self_links = vpc.subnets_self_links,
  } }
}

output "network_name" {
  value = var.single_project ? module.vpc[local.index].network_name : null
}

output "network_id" {
  value = var.single_project ? module.vpc[local.index].network_id : null
}

output "network_project_number" {
  value = [for value in module.vpc_project : value.project_number]
}

output "network_project_id" {
  value = [for value in module.vpc_project : value.project_id]
}

output "network_self_link" {
  value = var.single_project ? module.vpc[local.index].network_self_link : null
}

output "subnetwork_name" {
  value = var.single_project ? module.vpc[local.index].subnets_names[0] : null
}

output "subnetwork_self_link" {
  value = var.single_project ? module.vpc[local.index].subnets_self_links[0] : null
}

output "common_folder_id" {
  value = try([for value in module.folder_common : value.ids["common"]][0], "")
}

output "org_id" {
  value = var.org_id
}

output "billing_account" {
  value = var.billing_account
}

output "teams" {
  value = { for team, group in module.group : team => module.group[team].id }
}

output "single_project" {
  value = var.single_project
}

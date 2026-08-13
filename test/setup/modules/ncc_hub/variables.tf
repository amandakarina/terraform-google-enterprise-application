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

variable "project_id_hub" {
  description = "The project ID to host the hub network in"
}

variable "network_name_hub" {
  description = "The name of the hub VPC network being created"
}

variable "auto_accept_projects_edge" {
  description = "List of project ids to be auto accept to NCC."
  type        = list(string)
}

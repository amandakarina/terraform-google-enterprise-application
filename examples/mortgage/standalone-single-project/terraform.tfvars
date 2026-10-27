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

project_id = "<YOUR-PROJECT-ID>"
# region     = "us-central1"

# Optional: If you already have a private worker pool, specify its ID. If not, a new one will be created.
# workerpool_id = "projects/PROJECT_ID/locations/LOCATION/workerPools/POOL_NAME"

# Optional: If a private worker pool is not provided, and you already have a VPC network to use for the private worker pool, specify its ID. If not, a new network will be created.
# network_id = "projects/PROJECT_ID/global/networks/NETWORK_NAME"

# Optional: Set to false if you do not want to create a NAT gateway (e.g. if your existing network already has one).
# create_nat = true

# Optional: Cloud Storage bucket to store logs
# logging_bucket = "your-gcs-logging-bucket"

# Optional: KMS Key to encrypt Cloud Storage buckets
# bucket_kms_key = "projects/PROJECT_ID/locations/LOCATION/keyRings/KEYRING/cryptoKeys/KEY"

# Optional: VPC Service Controls configuration
# service_perimeter_name = "<YOUR-SERVICE-PERIMETER-NAME>"
# service_perimeter_mode = "DRY_RUN"
# access_level_name      = "<YOUR-ACCESS-LEVEL-NAME>"

# Defines the GKE Fleet team scope, Kubernetes namespace, and the associated admin group/user email.
#teams = {"namespace" = "group@example.com"}

# The Cloud KMS asymmetric signing key used by Binary Authorization to sign image attestations.
# Note: The key purpose must be ASYMMETRIC_SIGN (e.g. RSA_SIGN_PKCS1_4096_SHA512).
# attestation_kms_key = "projects/PROJECT_ID/locations/LOCATION/keyRings/KEYRING/cryptoKeys/KEY"

# Optional: Network Connectivity Center (NCC) connection configuration
# ncc_config = {
#   enable_ncc                  = true
#   hub_uri                     = "projects/YOUR_HUB_PROJECT_ID/locations/global/hubs/YOUR_HUB_NAME"
#   spoke_group                 = "edge"
#   spoke_name                  = "vpc-spoke"
#   spoke_description           = "NCC Spoke for standalone cluster network"
#   spoke_labels                = { env = "dev" }
#   spoke_exclude_export_ranges = []
#   spoke_include_export_ranges = []
# }

cloudbuildv2_repository_config = {
  github_secret_id = null
  repo_type        = "GITLABv2"
  repositories = {
    "eab-mortgage-agent" = {
      repository_name = "eab-mortgage-agent"
      repository_url  = "https://gitlab.example.com/root/eab-mortgage-agent.git"
    }
  }
  # The Secret ID format is: projects/PROJECT_NUMBER/secrets/SECRET_NAME
  gitlab_authorizer_credential_secret_id      = "projects/1026699994150/secrets/gitlab-pat-from-vm"
  gitlab_read_authorizer_credential_secret_id = "projects/1026699994150/secrets/gitlab-pat-from-vm"
  gitlab_webhook_secret_id                    = "projects/eab-gitlab-e8xk/secrets/gitlab-webhook"
  secret_project_id                           = "eab-gitlab-e8xk"

  # If you are using a self-hosted instance, you may change the URL below accordingly
  gitlab_enterprise_host_uri = "https://gitlab.example.com"
  # Format is projects/PROJECT/locations/LOCATION/namespaces/NAMESPACE/services/SERVICE
  gitlab_enterprise_service_directory = "projects/eab-gitlab-e8xk/locations/us-west1/namespaces/gitlab-namespace/services/gitlab"
  # .pem string
  gitlab_enterprise_ca_certificate = <<EOF
-----BEGIN CERTIFICATE-----
MIIGKjCCBBKgAwIBAgIUIFTbolOg9U+7UiyPLJSI+TxVXBgwDQYJKoZIhvcNAQEL
BQAwgYQxCzAJBgNVBAYTAlhYMRIwEAYDVQQIDAlTdGF0ZU5hbWUxETAPBgNVBAcM
CENpdHlOYW1lMRQwEgYDVQQKDAtDb21wYW55TmFtZTEbMBkGA1UECwwSQ29tcGFu
eVNlY3Rpb25OYW1lMRswGQYDVQQDDBJnaXRsYWIuZXhhbXBsZS5jb20wHhcNMjYx
MDEzMjEzNjU2WhcNMzYxMDEwMjEzNjU2WjCBhDELMAkGA1UEBhMCWFgxEjAQBgNV
BAgMCVN0YXRlTmFtZTERMA8GA1UEBwwIQ2l0eU5hbWUxFDASBgNVBAoMC0NvbXBh
bnlOYW1lMRswGQYDVQQLDBJDb21wYW55U2VjdGlvbk5hbWUxGzAZBgNVBAMMEmdp
dGxhYi5leGFtcGxlLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
AJjjNy6t9YataOvO+CQgHRh8+yrM3A6UNoKoErIQFCHCenKdI87U/NNQWUzq7cFJ
malERgedwXdnuilJoBfw8BZLrxFxMJU/brFua60XzJZ5PZaFdacdF6B9QPqYq5Nh
U897qojl111xLYByw385aD1WLrBQSLTMtOwkxPnprLyOnJchEfilmGlI4DH8cZBG
p+3/7rw3+6rF3n1JEIuheM5rQ+HovagCjakDENpTWNyTpFA15Gw4/6H0xjuqM5XB
9zWzJydfwe07kIzb7pCWV9XJyv0uGLpIwTNPMC0YujJzOOUq9ScPjPMhfrYqG96f
ltYuiw8YrLFU2fU/PhqegaJQ0aCnty2S2xlqe1sFyjlytVUmFuUZOW7eD5TqhyoC
f1aGf4y/djSMIji03bgmO+S5vI3F6RX79d8P8nLwf7LaFH102ApamGMCjNIM+gkO
FnWFT1Vl4w0C9SBYx81nRJP5d7TLyn5FJcX6VffDf7/K1bTNEohcCIfeY066xG2z
iLme+HbeiMbwuApin3zRdUchg+BsEURCaP1X5G84hPG2QFYAC27qDbOpCFaKYEGj
VSF+WJ7ZPEwsC3d6rODWKTwfchcbE5RYmaDku2BWyrof60dXkk2u2L+rqciCli+X
rRET0go2vJmvl9oLO9TmOVw4QNp5Og69RXH1DCX4q7rRAgMBAAGjgZEwgY4wHQYD
VR0OBBYEFGW7FhkOFV72DGxhI1s6Y5trEGIXMB8GA1UdIwQYMBaAFGW7FhkOFV72
DGxhI1s6Y5trEGIXMA8GA1UdEwEB/wQFMAMBAf8wOwYDVR0RBDQwMoISZ2l0bGFi
LmV4YW1wbGUuY29thwSIQ4hLghYxMzYuNjcuMTM2Ljc1LnNzbGlwLmlvMA0GCSqG
SIb3DQEBCwUAA4ICAQAFZ0sZ13jYSWmiHSDKeCNSjcZ03rsyYc2gZgrxbzQ1dyqt
PL8tCBxc0YyZU2TDHkSnLu0RlL15BrU/Uk0KVNMXt6oVXA/HOXNCa67xVGPThAz3
bazOfOpRe4FLIbMaGhcS68iIiosPh7HnKJKCzOUafd4czGGpX4tc21QEs6Z5epXV
cistm2O+YTh7n/t4flp+YWnB8ALuQErlmqX+3Z7w0ZOJO7cXiVa8Te+IV2UW5sEs
XZ/KgGhAgHdyrQw7IqOLP/HGyifV7gsha+OZcgZgRWf0p3EmPpU+OQ2PNv4FIKQ6
fo6XtCMyDWpr6UvibFJHnkDYqUuDDB96ugkMMFm3axVTWGh6ZU5ABiHGrlEn9/Mh
OB5HflZbQcnS76Eu3ZTVL+WtBVObeIcpGsG7EeEOT2Suwmg4CW7UklPlE79/rJce
6QTKNp3pvDaKcud9cG09jzA+SUCx9xmAlqQ8GEP4OACSyrOQlaC5hqZczgXvYs0v
PwUk24yzQiLSZd0XQZdgqACFW7TulNKdbYrHIR9gp+HaukIqyF+dF418EvWHdAG6
qKWV2WcyImWCJE2NCov3fdD8/Y6xREfLmD/TbtE78aKQozRDVaj815wprwm8i7Y6
wPr7d9rDoP0kHshvp6n9QD4tA2tt1nDKofBW1vCx2qhG8WhAyiab8TJ+dszChw==
-----END CERTIFICATE-----
EOF
}

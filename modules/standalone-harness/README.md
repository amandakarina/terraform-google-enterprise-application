# Standalone Harness Module

This module provisions the foundational harness infrastructure for single-project / standalone deployments in the Enterprise Application Blueprint.

It provisions:
* Essential Google Cloud APIs
* A private Cloud Build Worker Pool (optional if `workerpool_id` is passed)
* Binary Authorization attestor image build
* Cluster VPC Network and subnets with secondary ranges

## Usage

```hcl
module "standalone_harness" {
  source = "../../modules/standalone-harness"

  project_id          = var.project_id
  region              = var.region
  workerpool_id       = var.workerpool_id
  network_id          = var.network_id
  create_nat          = var.create_nat
  additional_services = ["modelarmor.googleapis.com"]
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_services | Additional GCP services to enable in the project. | `list(string)` | `[]` | no |
| base\_cidr | Base CIDR for the VPC primary ranges | `string` | `"10.1.0.0/24"` | no |
| create\_nat | Enables Cloud NAT creation for Private Worker Pool. | `bool` | `true` | no |
| enables\_network\_connection\_and\_peering\_routes | Enables Network connection and peering routes. | `bool` | `true` | no |
| hub\_network\_name | The name of the VPC being created | `string` | n/a | yes |
| logging\_bucket | Bucket to store logging. | `string` | `null` | no |
| ncc\_hub\_uri | The NCC Hub ID | `string` | n/a | yes |
| network\_id | The network ID where the private worker pool is going to be peered. | `string` | `null` | no |
| pods\_base\_cidr | Base CIDR for Kubernetes Pods secondary ranges | `string` | `"10.2.0.0/20"` | no |
| project\_id | Google Cloud project ID in which to deploy all harness resources. | `string` | n/a | yes |
| region | Google Cloud region for deployments. | `string` | `"us-central1"` | no |
| regions | Google Cloud regions for cluster | `list(string)` | n/a | yes |
| secondary\_ip\_cidr\_range\_01 | Secondary CIDR range 1 for pods/services. | `string` | `"192.168.0.0/18"` | no |
| secondary\_ip\_cidr\_range\_02 | Secondary CIDR range 2 for pods/services. | `string` | `"192.168.64.0/18"` | no |
| services\_base\_cidr | Base CIDR for Kubernetes Services secondary ranges | `string` | `"10.3.0.0/16"` | no |
| subnet\_ip | Primary subnet CIDR block. | `string` | `"10.1.20.0/24"` | no |
| vpc\_name | Name of the VPC to create. | `string` | `"eab-cluster"` | no |
| workerpool\_id | Specifies the Cloud Build Worker Pool that will be utilized for triggers. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| binary\_authorization\_image | Binary Authorization attestor image. |
| binary\_authorization\_repository\_id | Binary Authorization repository ID. |
| required\_services | The required Google project service resources. |
| subnets\_self\_links | Self links of the created subnets. |
| workerpool\_id | The Cloud Build Worker Pool ID. |
| workerpool\_network\_project\_id | The network project ID for the workerpool. |
| workerpool\_project\_id | The Cloud Build Worker Pool Project ID. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

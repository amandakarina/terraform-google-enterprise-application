# Stage 1: Platform Infrastructure (Platform Team)

This stage provisions the foundational platform infrastructure for the Capital Agent deployment, including the cluster network connected to the **Network Connectivity Center (NCC)** by default, the private GKE cluster, Cloud Armor security policies, and GKE Fleet governance.

## Persona
- **Platform Team** (Cloud Platform Engineer / Network Administrator)

## Responsibilities
- Provision the Cluster VPC network, subnets (nodes, pods, services, and proxy-only for Gateway API), and Cloud NAT.
- Attach the VPC as an NCC Spoke to the enterprise NCC Hub (`ncc_config`).
- Attach the Cluster Service Project (`cluster_project_id`) to the Shared VPC (`network_project_id`).
- Provision the Private Multi-tenant GKE Cluster (Autopilot or Standard) with private endpoints and no external IPs on nodes.
- Register the cluster to the GKE Fleet, configure the team scope, and create the `capital-agent` namespace.

## Prerequisites
- A Google Cloud project for networking (`network_project_id`).
- A Google Cloud project for the GKE cluster (`cluster_project_id`).
- (Optional) An existing NCC Hub URI if `enable_ncc = true`.

## Usage

1. Copy the sample variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Update `terraform.tfvars` with your project IDs and regional settings.
3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

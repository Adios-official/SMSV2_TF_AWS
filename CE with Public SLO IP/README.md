# Customer Edge (CE) with Public IP Assignment (Usable for All Normal Use Cases)

## Overview

This folder contains Terraform configurations to deploy a Customer Edge (CE) in AWS with **public IP assignment** and no **NAT** configurations. It dynamically handles deployments for:

- Single-node CE or High Availability (HA) CE with three nodes.
- Single NIC or dual NIC setups.

This setup integrates with Volterra (F5 Distributed Cloud) and AWS, making it suitable for environments requiring secure and scalable edge deployments.

---

## Folder Structure and Key Files

### 1. `main.tf`

This file defines the main resources:

- `aws_instance`: Provisions CE instances in AWS based on the specified configurations.
- `aws_eip` and `aws_eip_association`: Handles Elastic IP assignments dynamically.
- `aws_security_group`: Manages security groups for SLO and SLI traffic.
- `volterra_securemesh_site_v2`: Creates a site object in Volterra.
- `volterra_token`: Generates a site token for provisioning.

**Key Features:**
- Dynamically manages instance count and NIC configuration based on variables (`num_nodes`, `num_nics`).
- Configures SLO and SLI network interfaces.
- Includes metadata for SSH keys and user data (e.g., proxy settings, site token).
- Validates configurations for public IPs, network interface assignments, and node availability.

### 2. `provider.tf`

This file specifies the providers required for the deployment:

- **AWS (aws)**: Manages AWS resources.
- **Volterra (volterra)**: Integrates with Volterra APIs for site creation and token generation.

### 3. `terraform.tfvars`

This file contains user-defined values for variables. Update this file with your specific project details and configuration, such as:

- AWS region, instance type, and other settings.
- Network configurations (VPC, subnets, security groups).
- Volterra API credentials and proxy settings.

### 4. `variables.tf`

This file declares and validates variables used across the configuration. Key variables include:

- **Basic Configuration**: `region`, `cluster_name`, `instance_type`, etc.
- **Network Settings**: `slo_subnet_ids`, `sli_subnet_ids`.
- **Public IP Configuration**: `eip_config` (handles Elastic IP assignment).
- **Security Groups**: `security_group_config` for SLO and SLI traffic.

---

## Usage Instructions

### 1. Prerequisites

- Install Terraform (v1.3.0 or later).
- Have an AWS account with necessary permissions.
- Obtain Volterra API credentials (.p12 file and API URL).

### 2. Configuration Steps

Update the `terraform.tfvars` file with:

- AWS region and instance details (`region`, `instance_type`, etc.).
- Desired cluster configuration (e.g., single or HA CE, single or dual NIC).
- Networking information (VPC ID, subnets, availability zones).
- SSH key pair name for node access.
- Ensure the Volterra API credentials (`api_p12_file`, `api_url`) are available and correctly configured.

### 3. Deployment Steps

- Initialize the Terraform working directory:
  ```bash
  terraform init

- Validate the configuration:
  ```bash
  terraform validate

- Preview the planned infrastructure changes:
  ```bash
  terraform plan

- Apply the configuration to create resources:
  ```bash
  terraform apply

## 4. Post-Deployment

- Verify the created CE instances in the GCP console.
- Validate the Volterra site object and token.

## Notes and Considerations

- Ensure the **subnets** and **availability zones** align with your desired architecture.
- For **dual NIC setups**, both `slo_subnet_ids` and `sli_subnet_ids` must have values for each node.
- **Public IP assignment** to the SLO network interfaces is handled dynamically. You can choose to assign new static IPs or use existing IPs based on the `eip_config` variable.
- **High Availability (HA)** mode is automatically enabled when `num_nodes` is set to 3.
- **Single NIC setups**: Ensure that only **one NIC per node** is assigned to the appropriate subnet. AWS requires each network interface to have a valid security group and subnet configuration.

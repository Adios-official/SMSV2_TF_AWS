# F5 XC SMSV2 Customer Edge (CE) for AWS

🚀 This Terraform project deploys F5 Distributed Cloud (XC) SMSV2 (Secure Mesh Site V2) Customer Edge (CE) nodes on AWS.

This is a **unified and flexible** configuration. This module allows you to select your desired architecture by changing variables in the `terraform.tfvars` file.

This single codebase can handle:
* **"Cluster" Model**: A standard 1-node or 3-node Cluster site. 
* **"vSite" Model**: Deploys 1, 2, or 3 independent nodes that are grouped into a single Virtual Site. This is the vsite based HA model.

Refer : https://community.f5.com/kb/technicalarticles/f5-distributed-cloud-%E2%80%93-ce-high-availability-options-a-comparative-exploration/330189
* **Public IP**: Can create new Elastic IPs, use existing EIPs, or assign no public IP at all.
* **NICs**: Supports both single-NIC (SLO only) and dual-NIC (SLO + SLI) deployments.

## Table of Contents
* [Core Configuration Concepts](#core-configuration-concepts)
  * [Deployment Model: Cluster vs. vSite](#1-deployment-model-cluster-vs-vsite)
  * [Networking: Public IP vs. NAT Gateway](#2-networking-public-ip-vs-nat-gateway)
  * [Node & NIC Count](#3-node--nic-count)
* [Prerequisites](#prerequisites)
* [File Structure](#file-structure)
* [How to Deploy](#how-to-deploy)
* [How to Destroy](#how-to-destroy)
* [Troubleshooting & FAQ](#troubleshooting--faq)

---

## Core Configuration Concepts

You control the entire deployment architecture using the variables in `terraform.tfvars`.

### 1. Deployment Model: Cluster vs. vSite

The `deployment_model` variable is the most important choice. It determines the F5 XC site topology.

* **`"cluster"`: (Standard Cluster Model)**
    * Creates **one** `volterra_securemesh_site_v2` resource in F5 XC.
    * If `num_nodes = 1`, it will be a single node cluster
    * If `num_nodes = 3`, it will be a 3 node cluster
    * All nodes (1 or 3) use a single, shared registration token.
    * **Use this model** for standard single-node or 3-node Cluster sites.

* **`"vsite"`: (Virtual Site Model)**
    * Creates **one** `volterra_securemesh_site_v2` resource *per node*. (e.g., `num_nodes = 2` creates 2 separate site objects).
    * Creates a `volterra_virtual_site` resource that groups all the individual sites together using a shared label.
    * Each node gets its own unique registration token.
    * **Use this model** to deploy multiple, independent nodes but manage them as a single logical group in F5 XC as a Virtual Site.



### 2. Networking: Public IP vs. NAT Gateway

The `public_ip_mode` variable controls how public IPs are (or are not) assigned to the SLO (eth0) interface.

* **`"CREATE_EIP"`**: **(Default)**
    * Terraform will create a new AWS Elastic IP (EIP) for each node and attach it.
    * Use this for simple "greenfield" deployments where you want the nodes to be reachable from the internet (e.g., for Site-to-Site VPN).

* **`"USE_EXISTING_EIP"`**:
    * Terraform will use a list of EIP Allocation IDs you provide in `existing_eip_allocation_ids`. The list count must match `num_nodes`.
    * Use this if you have already reserved specific EIPs for this purpose.

* **`"NONE"`**: **(NAT / Proxy Model)**
    * No public IP will be assigned.
    * This is the correct choice for "brownfield" deployments where nodes are in a **private subnet** and egress traffic is handled by an existing **AWS NAT Gateway** or an HTTP proxy.
    * **If you select `NONE`, you must ensure your private subnet's route table has a route to the internet (e.g., `0.0.0.0/0` via a NAT Gateway) so the node can register with F5 XC.**

### 3. Node & NIC Count

* `num_nodes`: The number of EC2 instances to deploy.
    * If `deployment_model = "cluster"`, must be `1` or `3`.
    * If `deployment_model = "vsite"`, can be `1`, `2`, or `3`.
* `num_nics`: The number of network interfaces per node.
    * `1`: Deploys only an SLO (eth0) interface.
    * `2`: Deploys both an SLO (eth0) and an SLI (eth1) interface.

---

## Prerequisites

1.  **Terraform** (v1.3.0 or newer).
2.  **AWS Account** with credentials configured for Terraform (e.g., via AWS CLI `aws configure`).
3.  **F5 Distributed Cloud Account** and an **API Credential (`.p12` file)**.

---

## File Structure

* `main.tf`: Contains the primary logic for creating all AWS (EC2, NICs, EIPs, SGs) and F5 XC (site, token, label, vsite) resources.
* `variables.tf`: Defines all input variables, including their types, descriptions, and validation rules.
* `provider.tf`: Declares the `aws` and `volterra` (F5 XC) providers.
* `terraform.tfvars.example`: A template for you to copy and fill in with your specific values. (**Do not** commit your real `terraform.tfvars` file.)
* `outputs.tf`: Defines outputs, such as the public IPs of the created nodes.
* `README.md`: This file.

---

## How to Deploy

1.  **Clone this Repository**
    ```bash
    git clone <your-repo-url>
    cd <your-repo-name>
    ```

2.  **Create your Variables File**
    Rename the example file to create your own variable definitions.
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```

3.  **Edit `terraform.tfvars`**
    This is the most important step. Fill in all the required values.

    * **XC Credentials:** `api_p12_file`, `api_url`
    * **Deployment Model:** `deployment_model`, `cluster_name`, `num_nodes`, `num_nics`
    * **AWS Compute:** `region`, `ami`, `instance_type`, `key_pair`
    * **AWS Networking:** `vpc_id`, `az_names`, `slo_subnet_ids`, `sli_subnet_ids` (if `num_nics = 2`)
    * **IP Configuration:** `public_ip_mode`, `existing_eip_allocation_ids` (if needed)
    * **Security Groups:** `security_group_config`

    **Note:** The number of items in `az_names` and `slo_subnet_ids` (and `sli_subnet_ids` if used) **must** match your `num_nodes` value.

4.  **Initialize Terraform**
    ```bash
    terraform init
    ```

5.  **Plan the Deployment**
    Review the changes Terraform will make.
    ```bash
    terraform plan
    ```

6.  **Apply the Configuration**
    Type `yes` to approve the deployment.
    ```bash
    terraform apply
    ```

---

## How to Destroy

To tear down all resources created by this project, run the destroy command.

```bash
terraform destroy

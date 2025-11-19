# F5 XC SMSV2 Customer Edge (CE) for AWS

🚀 This Terraform project deploys F5 Distributed Cloud (XC) SMSV2 (Secure Mesh Site V2) Customer Edge (CE) nodes on AWS. This code is updated as per the latest release of Nov 16 2025

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
* [Deployment Outputs](#deployment-outputs)
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
* `terraform.tfvars`: A template for you to copy and fill in with your specific values. 
* `outputs.tf`: Defines outputs, such as the public IPs of the created nodes.
* `README.md`: This file.

---

## How to Deploy

1.  **Clone this Repository**
    ```bash
    git clone <your-repo-url>
    cd <your-repo-name>
    ```


2.  **Edit `terraform.tfvars`**
    This is the most important step. Fill in all the required values. If you want you can save the file from this repo, copy to a new file and use that as a template.

    * **XC Credentials:** `api_p12_file`, `api_url`
    * **Deployment Model:** `deployment_model`, `cluster_name`, `num_nodes`, `num_nics`
    * **AWS Compute:** `region`, `ami`, `instance_type`, `key_pair`
    * **AWS Networking:** `vpc_id`, `az_names`, `slo_subnet_ids`, `sli_subnet_ids` (if `num_nics = 2`)
    * **IP Configuration:** `public_ip_mode`, `existing_eip_allocation_ids` (if needed)
    * **Security Groups:** `security_group_config`

    **Note:** The number of items in `az_names` and `slo_subnet_ids` (and `sli_subnet_ids` if used) **must** match your `num_nodes` value.

3.  **Initialize Terraform**
    ```bash
    terraform init
    ```

4.  **Plan the Deployment**
    Review the changes Terraform will make.
    ```bash
    terraform plan
    ```

5.  **Apply the Configuration**
    Type `yes` to approve the deployment.
    ```bash
    terraform apply
    ```

---

## How to Destroy

To tear down all resources created by this project, run the destroy command.

```bash
terraform destroy
```
## Deployment Outputs

After a successful `terraform apply`, this module provides structured outputs for you to easily see what was created.

### 1. Deployment Summary

To see a complete summary of all the resources you deployed, run:

```bash
terraform output deployment_summary
```
This will display a structured object containing key information, such as:
* AWS Instance IDs and Availability Zones
* Public and Private IP addresses
* Created Security Group IDs (if any)
* F5 XC Site Names
* The F5 XC Virtual Site Name (if created)
* A summary of your chosen inputs (like `deployment_model`, `node_count`, etc.)

Sample Output VSITE Model
```bash
deployment_summary = {
  "aws_instance_azs" = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]
  "aws_instance_ids" = [
    "i-002f7b13f11905e3d",
    "i-05165acf134c71212",
    "i-0edc83f6c08811028",
  ]
  "aws_region" = "us-east-1"
  "cluster_name" = "my-aws-site"
  "created_security_groups" = {
    "sli" = "sg-04187191e68bb8eb5"
    "slo" = "sg-02e8d161137c3ce2d"
  }
  "deployment_model" = "vsite"
  "f5_xc_site_names" = [
    "my-aws-site-1",
    "my-aws-site-2",
    "my-aws-site-3",
  ]
  "f5_xc_virtual_site_name" = "my-aws-site-vsite"
  "nic_count" = 2
  "node_count" = 3
  "private_ips_slo" = [
    "10.0.1.79",
    "10.0.2.139",
    "10.0.3.54",
  ]
  "private_ips_sli" = [
    "10.10.1.100",
    "10.10.2.100",
    "10.10.3.100",
  ]
  "public_ip_mode" = "CREATE_EIP"
  "public_ips_slo" = [
    "3.76.148.184",
    "18.184.148.129",
    "18.156.96.150",
  ]
}
```

Sample Output CLUSTER Model
```bash
deployment_summary = {
  "aws_instance_azs" = [
    "eu-central-1a",
    "eu-central-1b",
    "eu-central-1c",
  ]
  "aws_instance_ids" = [
    "i-03b7a581c7142c3ff",
    "i-02b320a6edb3a1449",
    "i-040628d2e5f24c061",
  ]
  "aws_region" = "eu-central-1"
  "cluster_name" = "aws-ha-model-11"
  "created_security_groups" = {
    "sli" = "sg-095fe12d3ca44df13"
    "slo" = "sg-09b568cf48d401ddc"
  }
  "deployment_model" = "cluster"
  "f5_xc_site_names" = [
    "aws-ha-model-11",
  ]
  "f5_xc_virtual_site_name" = "N/A (Cluster Model)"
  "nic_count" = 2
  "node_count" = 3
  "private_ips_sli" = [
    "10.0.11.72",
    "10.0.12.212",
    "10.0.13.47",
  ]
  "private_ips_slo" = [
    "10.0.1.105",
    "10.0.2.192",
    "10.0.3.94",
  ]
  "public_ip_mode" = "CREATE_EIP"
  "public_ips_slo" = [
    "35.156.248.106",
    "3.76.239.28",
    "63.180.128.168",
  ]
}
```
## Troubleshooting & FAQ

**Q: `terraform plan` fails with a "Invalid value" error from a `check` block.**
* **A:** This is by design. We use `check` blocks to validate your variable combinations *before* creating resources. Read the error message carefully. It will tell you exactly what is wrong.
    * **Example 1:** `Invalid EIP configuration: ... 'existing_eip_allocation_ids' must contain exactly 3 ID(s).`
        * **Fix:** You set `num_nodes = 3` and `public_ip_mode = "USE_EXISTING_EIP"`, but your `existing_eip_allocation_ids` list does not contain 3 items. Add the correct number of EIP IDs.
    * **Example 2:** `Invalid node count: For 'cluster' model, num_nodes must be 1 or 3.`
        * **Fix:** You set `deployment_model = "cluster"` and `num_nodes = 2`. This is an invalid combination. Change `num_nodes` to `1` or `3`.

**Q: `terraform apply` fails with an error about `element()` or `count.index`.**
* **A:** This almost always means your lists in `terraform.tfvars` do not have the same number of items as `num_nodes`.
* **Fix:** Ensure that the number of items in `az_names`, `slo_subnet_ids`, and (if used) `sli_subnet_ids` *exactly* matches the value of `num_nodes`.

**Q: My EC2 instances were created, but the site never comes "Online" in the F5 XC Console.**
* **A:** This means the CE node cannot communicate with the F5 XC global network to register. This is an **egress connectivity problem**.
* **Fix:**
    1.  **Check your `public_ip_mode`:**
        * If `"CREATE_EIP"` or `"USE_EXISTING_EIP"`: Ensure your **SLO Security Group** (`security_group_config`) allows outbound (egress) traffic on TCP port 443. If you used `create_slo_sg = true`, this is done for you. If you used an existing SG, you must add this rule.
        * If `"NONE"`: This is the most common cause. Your **private subnet** (where the SLO NIC lives) **must** have a route table entry that directs internet-bound traffic (e.g., `0.0.0.0/0`) to an **AWS NAT Gateway**. Without this, the node has no way to call home.
    2.  **Test Connectivity:** SSH into the EC2 instance using your `key_pair`. Once inside, run `curl -v https://google.com`. If this fails or times out, your AWS networking (Route Tables, Security Groups, or NAT Gateway) is not configured correctly for egress.

**Q: `terraform plan` fails with an "Invalid cluster_name" error.**
* **A:** Your `cluster_name` does not meet the DNS-1035 label standard.
* **Fix:** The name must be all lowercase, can contain numbers and hyphens (`-`), must start with a letter, and must end with a letter or number.
    * **Good:** `my-f5-site-1`
    * **Bad:** `My-Site`, `1-site-f5`, `my-site-`

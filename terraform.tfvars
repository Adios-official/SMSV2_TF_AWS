################################################################################
# 1. F5 DISTRIBUTED CLOUD (XC) API CREDENTIALS
################################################################################

# Path to your F5 XC API credential file
api_p12_file = "your-creds.p12"

# URL for the F5 XC API
api_url = "https://<tenant-name>.console.ves.volterra.io/api"

################################################################################
# 2. DEPLOYMENT MODEL & SITE CONFIGURATION
################################################################################

# The logical deployment model.
# - "cluster": Creates 1 XC site object. HA is enabled if num_nodes = 3.
# - "vsite":   Creates 1 XC site object PER NODE (e.g., 3 nodes = 3 sites).
#              These sites are grouped by a single virtual_site. HA is
#              always disabled for each site object.
deployment_model = "cluster"

#-------------------------------------------------------------------------------
# IMPORTANT NOTE ON DEPLOYMENT MODEL:
#
# "cluster": Use this for a standard single-site or 3-node HA deployment.
#   - 1 or 3 nodes.
#   - 1 `volterra_securemesh_site_v2` resource.
#   - 1 `volterra_token` (shared by all nodes).
#
# "vsite": Use this to deploy multiple, independent nodes as a single logical group.
#   - 1, 2, or 3 nodes.
#   - Creates `num_nodes` (e.g., 2) `volterra_securemesh_site_v2` resources.
#   - Creates `num_nodes` (e.g., 2) `volterra_token` resources (one per node).
#   - Creates 1 `volterra_virtual_site` to group them all.
#-------------------------------------------------------------------------------

# Base name for the site(s) and AWS resources. Must be a valid DNS-1035 label.
# (e.g., "my-aws-site")
cluster_name = "my-aws-site"

# Number of CE nodes to deploy.
# - If deployment_model = "cluster", must be 1 or 3.
# - If deployment_model = "vsite", can be 1, 2, or 3.
num_nodes = 1

# Number of network interfaces (NICs) per node.
# - 1 = Single-NIC (SLO only)
# - 2 = Dual-NIC (SLO + SLI)
num_nics = 1

################################################################################
# 3. AWS COMPUTE & IMAGE CONFIGURATION
################################################################################

# AWS Region where resources will be deployed
region = "us-east-1"

# AWS EC2 instance type (medium node : "m5.2xlarge" | Ref : https://docs.cloud.f5.com/docs-v2/multi-cloud-network-connect/reference/ce-site-size-ref)
instance_type = "t3.xlarge"

# AWS AMI ID for the F5 XC CE nodes | Check with your F5 contact to get the latest ami details
ami = "ami-xxxxxxxxxxxxxxxxx"
#-------------------------------------------------------------------------------
# NOTE ON FINDING THE LATEST AMI:
# You can use the AWS CLI to find the latest F5 XC CE AMI in your target region.
# Example (adjust --region as needed):
#
# aws ec2 describe-images \
#   --region us-east-1 \
#   --filters "Name=name,Values=*f5xc-ce*" \
#   --query "reverse(sort_by(Images, &CreationDate))[*].{ImageId:ImageId,Name:Name,CreationDate:CreationDate}" \
#   --output table
#
#-------------------------------------------------------------------------------

# SSH key pair name for accessing the instances
key_pair = "my-aws-keypair"

# Root disk configuration for each node
root_block_device = {
  volume_size = 80    # Disk size in GB (min 120) - NOTE: Check docs for your instance type
  volume_type = "gp2" # EBS volume type
  encrypted   = false # (Optional) Enable encryption
}

# AWS Availability Zones.
# NOTE: The number of items in this list MUST match 'num_nodes'.
az_names = [
  "us-east-1a", # For node-1
  # "us-east-1b", # For node-2 (uncomment if num_nodes > 1)
  # "us-east-1c", # For node-3 (uncomment if num_nodes = 3)
]

# Custom tags to apply to all created AWS resources
tags = {
  Environment = "Development"
  Project     = "F5XC"
  Owner       = "user@example.com"
}

################################################################################
# 4. AWS NETWORKING & SECURITY CONFIGURATION
################################################################################

# VPC ID where the nodes will be deployed
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# --- Site Local Outside (SLO) Network ---
# Subnet IDs for the SLO (eth0) interface.
# NOTE: The number of items in this list MUST match 'num_nodes'.
slo_subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx", # For node-1
  # "subnet-yyyyyyyyyyyyyyyyy", # For node-2 (uncomment if num_nodes > 1)
  # "subnet-zzzzzzzzzzzzzzzzz", # For node-3 (uncomment if num_nodes = 3)
]

# --- Site Local Inside (SLI) Network (Used only if num_nics = 2) ---
# Subnet IDs for the SLI (eth1) interface.
# NOTE: The number of items in this list MUST match 'num_nodes' if num_nics = 2.
sli_subnet_ids = [
  "subnet-aaaaaaaaaaaaaaaaa", # For node-1
  # "subnet-bbbbbbbbbbbbbbbbb", # For node-2 (uncomment if num_nodes > 1)
  # "subnet-ccccccccccccccccc", # For node-3 (uncomment if num_nodes = 3)
]

# --- Public IP Assignment ---
# How to handle public IPs for the SLO interface.
# - "CREATE_EIP":       Terraform will create a new Elastic IP for each node.
# - "USE_EXISTING_EIP": Terraform will use the IPs from 'existing_eip_allocation_ids'.
# - "NONE":             No public IP will be assigned (e.g., for NAT Gateway).
public_ip_mode = "CREATE_EIP"

# List of existing Elastic IP Allocation IDs.
# Only used if public_ip_mode = "USE_EXISTING_EIP".
# NOTE: The number of items in this list MUST match 'num_nodes'.
existing_eip_allocation_ids = [
  # "eipalloc-xxxxxxxxxxxxxx", # For node-1
  # "eipalloc-yyyyyyyyyyyyyy", # For node-2
  # "eipalloc-zzzzzzzzzzzzzz", # For node-3
]

# --- Security Groups ---
# Configure Security Groups for SLO and SLI interfaces.
security_group_config = {
  # Set to 'true' to create new, open SGs. 'false' to use existing.
  create_slo_sg = true
  create_sli_sg = true

  # Provide SG ID if create_slo_sg = false
  existing_slo_sg_id = ""

  # Provide SG ID if create_sli_sg = false (and num_nics = 2)
  existing_sli_sg_id = ""

  #-----------------------------------------------------------------------------
  # NOTE ON SLI SECURITY GROUP:
  # If 'num_nics' is set to 1, the 'create_sli_sg' and 'existing_sli_sg_id'
  # settings are safely ignored. Terraform logic will not attempt to create
  # or use an SLI security group if 'num_nics = 1'.
  #-----------------------------------------------------------------------------
}

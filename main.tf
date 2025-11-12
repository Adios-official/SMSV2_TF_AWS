################################################################################
# 0. INPUT VALIDATIONS
#
# These 'check' blocks validate that variable combinations are correct
# before Terraform attempts to create any resources.
################################################################################

check "valid_node_count_for_model" {
  assert {
    condition = (
      (var.deployment_model == "cluster" && contains([1, 3], var.num_nodes)) ||
      (var.deployment_model == "vsite" && contains([1, 2, 3], var.num_nodes))
    )
    error_message = "Invalid node count: For 'cluster' model, num_nodes must be 1 or 3. For 'vsite' model, num_nodes can be 1, 2, or 3."
  }
}

check "valid_eip_configuration" {
  assert {
    condition = (
      (var.public_ip_mode == "USE_EXISTING_EIP" && length(var.existing_eip_allocation_ids) == var.num_nodes) ||
      (var.public_ip_mode != "USE_EXISTING_EIP" && length(var.existing_eip_allocation_ids) == 0)
    )
    error_message = "Invalid EIP configuration: If 'public_ip_mode' is 'USE_EXISTING_EIP', 'existing_eip_allocation_ids' must contain exactly ${var.num_nodes} ID(s). For 'CREATE_EIP' or 'NONE', 'existing_eip_allocation_ids' must be empty."
  }
}

check "valid_security_group_configuration" {
  # Validate the SLO group configuration (always required)
  assert {
    condition = (
      (var.security_group_config.create_slo_sg && length(var.security_group_config.existing_slo_sg_id) == 0) ||
      (!var.security_group_config.create_slo_sg && length(var.security_group_config.existing_slo_sg_id) > 0)
    )
    error_message = "Invalid SLO Security Group config: If 'create_slo_sg' is true, 'existing_slo_sg_id' must be empty. If 'create_slo_sg' is false, 'existing_slo_sg_id' must be provided."
  }

  # Validate the SLI group configuration (only if num_nics is 2)
  assert {
    condition = (
      var.num_nics == 1
    ) || (
      (var.security_group_config.create_sli_sg && length(var.security_group_config.existing_sli_sg_id) == 0) ||
      (!var.security_group_config.create_sli_sg && length(var.security_group_config.existing_sli_sg_id) > 0)
    )
    error_message = "Invalid SLI Security Group config (only applies if num_nics=2): If 'create_sli_sg' is true, 'existing_sli_sg_id' must be empty. If 'create_sli_sg' is false, 'existing_sli_sg_id' must be provided."
  }
}

################################################################################
# 1. F5 XC VIRTUAL SITE LABELS
#
# These resources are only created for the 'vsite' model.
# They are used by the 'volterra_virtual_site' to find and group
# the individual 'volterra_securemesh_site_v2' objects.
################################################################################

resource "volterra_known_label_key" "smsv2-vsite_key" {
  count = var.deployment_model == "vsite" ? 1 : 0

  key         = "${var.cluster_name}-vsite"
  namespace   = "shared"
  description = "key used for v-site creation"
}

resource "volterra_known_label" "smsv2-vsite_label" {
  count = var.deployment_model == "vsite" ? 1 : 0

  key         = volterra_known_label_key.smsv2-vsite_key[0].key
  namespace   = "shared"
  value       = "true"
  description = "label used for v-site creation"
  depends_on  = [volterra_known_label_key.smsv2-vsite_key]
}

################################################################################
# 2. AWS SECURITY GROUPS
#
# Created before Network Interfaces, which depend on them.
################################################################################

# Create SLO Security Group (if requested)
resource "aws_security_group" "slo_sg" {
  count = var.security_group_config.create_slo_sg ? 1 : 0

  name        = "${var.cluster_name}-slo-sg"
  description = "Security group for SLO interfaces"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.cluster_name}-slo-sg"
  }, var.tags)
}

# Create SLI Security Group (if requested and num_nics is 2)
resource "aws_security_group" "sli_sg" {
  count = var.num_nics == 2 && var.security_group_config.create_sli_sg ? 1 : 0

  name        = "${var.cluster_name}-sli-sg"
  description = "Security group for SLI interfaces (only when num_nics == 2)"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.cluster_name}-sli-sg"
  }, var.tags)
}


################################################################################
# 3. AWS NETWORKING (EIPs & NICS)
################################################################################

# Create new Elastic IP(s) if public_ip_mode is "CREATE_EIP"
resource "aws_eip" "example" {
  count = var.public_ip_mode == "CREATE_EIP" ? var.num_nodes : 0

  tags = {
    Name = "${var.cluster_name}-slo-nic-eip-${count.index + 1}"
  }
}

# Create SLO Network Interface(s)
resource "aws_network_interface" "slo_nics" {
  count     = var.num_nodes
  subnet_id = var.slo_subnet_ids[count.index]
  security_groups = var.security_group_config.create_slo_sg ? [aws_security_group.slo_sg[0].id] : [var.security_group_config.existing_slo_sg_id]

  tags = {
    Name = "${var.cluster_name}-slo-nic-${count.index + 1}"
  }
}

# Create SLI Network Interface(s) (only if num_nics is 2)
resource "aws_network_interface" "sli_nics" {
  count     = var.num_nics == 2 ? var.num_nodes : 0
  subnet_id = var.sli_subnet_ids[count.index]
  security_groups = var.security_group_config.create_sli_sg ? [aws_security_group.sli_sg[0].id] : [var.security_group_config.existing_sli_sg_id]

  tags = {
    Name = "${var.cluster_name}-sli-nic-${count.index + 1}"
  }
}


################################################################################
# 4. F5 XC SITE & TOKEN
#
# Creates the site object(s) and a corresponding token for each.
################################################################################

resource "volterra_securemesh_site_v2" "smsv2-site-object" {
  # 'vsite' model = 1 site per node. 'cluster' model = 1 site total.
  count = var.deployment_model == "vsite" ? var.num_nodes : 1

  # 'vsite' names are indexed (e.g., "my-site-1"), 'cluster' name is not.
  name      = var.deployment_model == "vsite" ? "${var.cluster_name}-${count.index + 1}" : var.cluster_name
  namespace = "system"

  # Apply labels only if in 'vsite' model
  labels = var.deployment_model == "vsite" ? {
    (volterra_known_label.smsv2-vsite_label[0].key) = (volterra_known_label.smsv2-vsite_label[0].value)
    } : {}

  block_all_services      = true
  logs_streaming_disabled = true

  # 'vsite' model always has HA disabled (as they are individual sites).
  # 'cluster' model enables HA only if num_nodes is 3.
  disable_ha = var.deployment_model == "vsite" || (var.deployment_model == "cluster" && var.num_nodes == 1)
  enable_ha  = var.deployment_model == "cluster" && var.num_nodes == 3

  re_select {
    geo_proximity = true
  }

  aws {
    not_managed {}
  }
  
  lifecycle {
    ignore_changes = [
      labels
    ]
  }

  # Explicit dependency on the label resource
  depends_on = [
    volterra_known_label.smsv2-vsite_label
  ]
}

# Create a registration token for each site object
resource "volterra_token" "smsv2-token" {
  # Count must match the 'volterra_securemesh_site_v2' count
  count = var.deployment_model == "vsite" ? var.num_nodes : 1

  name      = "${volterra_securemesh_site_v2.smsv2-site-object[count.index].name}-token"
  namespace = "system"
  type      = 1 # Site registration token
  site_name = volterra_securemesh_site_v2.smsv2-site-object[count.index].name

  depends_on = [volterra_securemesh_site_v2.smsv2-site-object]
}


################################################################################
# 5. AWS COMPUTE (EC2 INSTANCES)
#
# Creates the CE node(s) and injects the correct registration token
# via user_data.
################################################################################

resource "aws_instance" "ec2_instance" {
  count = var.num_nodes

  ami               = var.ami
  instance_type     = var.instance_type
  key_name          = var.key_pair
  availability_zone = element(var.az_names, count.index)
  #iam_instance_profile = var.instance_profile_name

  root_block_device {
    volume_size = var.root_block_device["volume_size"]
    volume_type = var.root_block_device["volume_type"]
  }

  # Attach the primary NIC (SLO)
  network_interface {
    network_interface_id = aws_network_interface.slo_nics[count.index].id
    device_index         = 0
  }

  # Attach the secondary NIC (SLI), only if num_nics == 2
  dynamic "network_interface" {
    for_each = var.num_nics == 2 ? [1] : []
    content {
      network_interface_id = aws_network_interface.sli_nics[count.index].id
      device_index         = 1
    }
  }

  # Select the correct token:
  # 'cluster' model: All nodes (1 or 3) use the *single* token (smsv2-token[0]).
  # 'vsite' model:   Each node (node[i]) uses its *matching* token (smsv2-token[i]).
  user_data = <<EOF
#cloud-config
write_files:
- path: /etc/vpm/user_data
  content: |
    token: ${var.deployment_model == "cluster" ? volterra_token.smsv2-token[0].id : volterra_token.smsv2-token[count.index].id}
  owner: root
  permissions: '0644'
EOF

  # Tags, including a dynamic 'ves-io-site-name' that matches the site name
  tags = merge({
    Name = "${var.cluster_name}-node-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "ves-io-site-name" = var.deployment_model == "vsite" ? "${var.cluster_name}-${count.index + 1}" : var.cluster_name
  }, var.tags)

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [volterra_token.smsv2-token]
}


################################################################################
# 6. AWS ATTACHMENTS (EIP ASSOCIATIONS)
#
# Attaches the Elastic IPs (new or existing) to the SLO NICs.
################################################################################

# Associate newly created Elastic IPs
resource "aws_eip_association" "associate_eip" {
  count                = var.public_ip_mode == "CREATE_EIP" ? var.num_nodes : 0
  network_interface_id = aws_network_interface.slo_nics[count.index].id
  allocation_id        = aws_eip.example[count.index].id
}

# Associate pre-existing Elastic IPs
resource "aws_eip_association" "associate_existing_eip" {
  count                = var.public_ip_mode == "USE_EXISTING_EIP" ? var.num_nodes : 0
  network_interface_id = aws_network_interface.slo_nics[count.index].id
  allocation_id        = var.existing_eip_allocation_ids[count.index]
}


################################################################################
# 7. F5 XC VIRTUAL SITE
#
# This resource is only created for the 'vsite' model.
# It uses the label from Block 1 to group all the sites from Block 4.
################################################################################

resource "volterra_virtual_site" "smsv2-vsite" {
  count = var.deployment_model == "vsite" ? 1 : 0

  name      = "${var.cluster_name}-vsite"
  namespace = "shared"
  site_type = "CUSTOMER_EDGE"
  
  # Selects all sites that have the label created in Block 1
  site_selector {
    expressions = ["${var.cluster_name}-vsite in (true)"]
  }

  # Add dependency to ensure labels are created first
  depends_on = [
    volterra_known_label.smsv2-vsite_label
  ]
}

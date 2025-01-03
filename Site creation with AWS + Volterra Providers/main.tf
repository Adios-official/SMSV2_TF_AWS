
##############################################################################################################################
# BLOCK 1 #  Create SMSV2 site object on XC
##############################################################################################################################
resource "volterra_securemesh_site_v2" "smsv2-site-object" {
  name      = var.cluster_name
  namespace = "system"
  block_all_services = true
  logs_streaming_disabled = true
  enable_ha = true
  re_select {
    geo_proximity = true
  }

  aws {
    not_managed {}
    }
  }


##############################################################################################################################
# BLOCK 2 #  Create site token on XC
##############################################################################################################################
resource "volterra_token" "smsv2-token" {
  name      = "${volterra_securemesh_site_v2.smsv2-site-object.name}-token"
  namespace = "system"
  type      = 1
  site_name = volterra_securemesh_site_v2.smsv2-site-object.name

  depends_on = [volterra_securemesh_site_v2.smsv2-site-object]
}
  
  

##############################################################################################################################
# BLOCK 3 # Create 1st EC2 instance in subnet 1 and AZ A
##############################################################################################################################
resource "aws_instance" "ec2_instance_1" {
  ami               = var.ami
  instance_type     = var.instance_type
  subnet_id         = var.subnet_id_1
  vpc_security_group_ids = var.security_group_ids
  key_name          = var.key_pair
  iam_instance_profile = var.instance_profile_name
  availability_zone = var.az_name_1

  root_block_device {
    volume_size = 80
    volume_type = "gp2"
  }

  user_data = <<EOF
#cloud-config
write_files:
- path: /etc/vpm/user_data
  content: |
    token: ${volterra_token.smsv2-token.id}
    proxy : ${var.proxy}
  owner: root
  permissions: '0644'
EOF

  associate_public_ip_address = false  # Disable auto-assign public IP

  tags = merge({
    Name = "${var.cluster_name}-node-1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "ves-io-site-name"         = var.cluster_name
  }, var.tags)

  depends_on = [volterra_token.smsv2-token]

 # provisioner "local-exec" {
 #   command = "sleep ${var.delay_between_nodes}"  # Wait for the specified delay after instance creation
 # }

  lifecycle {
    create_before_destroy = true
  }
}


##############################################################################################################################
# BLOCK 4 # Create 2nd EC2 instance in subnet 2 and AZ B
##############################################################################################################################
resource "aws_instance" "ec2_instance_2" {
  ami               = var.ami
  instance_type     = var.instance_type
  subnet_id         = var.subnet_id_2
  vpc_security_group_ids = var.security_group_ids
  key_name          = var.key_pair
  iam_instance_profile = var.instance_profile_name
  availability_zone = var.az_name_2

  root_block_device {
    volume_size = 80
    volume_type = "gp2"
  }

  user_data = <<EOF
#cloud-config
write_files:
- path: /etc/vpm/user_data
  content: |
    token: ${volterra_token.smsv2-token.id}
    proxy : ${var.proxy}
  owner: root
  permissions: '0644'
EOF

  associate_public_ip_address = false  # Disable auto-assign public IP

  tags = merge({
    Name = "${var.cluster_name}-node-2"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "ves-io-site-name"         = var.cluster_name
  }, var.tags)

 # provisioner "local-exec" {
 #   command = "sleep ${var.delay_between_nodes}"  # Wait for the specified delay after instance creation
 # }

  depends_on = [aws_instance.ec2_instance_1]

  lifecycle {
    create_before_destroy = true
  }
}


##############################################################################################################################
# BLOCK 5 # Create 3rd EC2 instance in subnet 3 and AZ C
##############################################################################################################################
resource "aws_instance" "ec2_instance_3" {
  ami               = var.ami
  instance_type     = var.instance_type
  subnet_id         = var.subnet_id_3
  vpc_security_group_ids = var.security_group_ids
  key_name          = var.key_pair
  iam_instance_profile = var.instance_profile_name
  availability_zone = var.az_name_3

  root_block_device {
    volume_size = 80
    volume_type = "gp2"
  }

  user_data = <<EOF
#cloud-config
write_files:
- path: /etc/vpm/user_data
  content: |
    token: ${volterra_token.smsv2-token.id}
    proxy : ${var.proxy}
  owner: root
  permissions: '0644'
EOF

  associate_public_ip_address = false  # Disable auto-assign public IP

  tags = merge({
    Name = "${var.cluster_name}-node-3"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "ves-io-site-name"         = var.cluster_name
  }, var.tags)

  depends_on = [aws_instance.ec2_instance_2]

  lifecycle {
    create_before_destroy = true
  }
}

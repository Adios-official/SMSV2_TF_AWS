provider "aws" {
  region = var.region  # Region set from variables
}

# Create 1st EC2 instance in subnet 1 and AZ A
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
    token: ${var.token}
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

 # provisioner "local-exec" {
 #   command = "sleep ${var.delay_between_nodes}"  # Wait for the specified delay after instance creation
 # }

  lifecycle {
    create_before_destroy = true
  }
}

# Create 2nd EC2 instance in subnet 2 and AZ B
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
    token: ${var.token}
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

# Create 3rd EC2 instance in subnet 3 and AZ C
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
    token: ${var.token}
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

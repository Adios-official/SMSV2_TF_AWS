#NOTE : Visual Studio code may throw errors that some arugments are not required here. You can ignroe those errors.

# AWS Region
#CHANGE THIS
region = "eu-central-1"

# Base name for EC2 instances
# This should be same as the name of the Site / Cluster
#CHANGE THIS
cluster_name = "adios-bugtest4-0911"

# Suffix for EC2 instances
# This is the suffix for the node name. Full node name would be Base name for EC2 instances + Suffix for EC2 instances
#CHANGE THIS
ec2_instance_name_1 = "node-1"
ec2_instance_name_2 = "node-2"
ec2_instance_name_3 = "node-3"

# VPC and Subnet IDs (1st, 2nd, and 3rd instance in different subnets and AZs)
#CHANGE THIS
vpc_id     = "vpc-xxxxxxxxxxxxxxxxx"
subnet_id_1 = "subnet-xxxxxxxxxxxxxxxxx"  # For node-1
subnet_id_2 = "subnet-xxxxxxxxxxxxxxxxx"  # For node-2
subnet_id_3 = "subnet-xxxxxxxxxxxxxxxxx"  # For node-3

# Availability Zones (one for each node)
#CHANGE THIS
az_name_1 = "eu-central-1a"
az_name_2 = "eu-central-1b"
az_name_3 = "eu-central-1c"

# Security Group
#CHANGE THIS
security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]

# Key Pair Name
#CHANGE THIS
key_pair = "sample_key_pair"

# IAM Instance Profile to be attached to EC2
#CHANGE THIS
instance_profile_name = "xxxxxxxxxx"

# AMI
#Below AMI ID is for eu-central-1
#CHANGE THIS
ami = "ami-0d43e733ea176527a"

# Instance Type
instance_type = "t3.xlarge"

# Storage
root_block_device = {
  volume_size = 80
}

# User Data (Cloud-init to write token to /etc/vpm/user_data)
#GENERATE TOKEN VALUE FROM XC CONSOLE
#USE PROXY IF NEEDED ELSE DELETE THAT LINE
token = "xxxxxxxxxxxxxx"
proxy = "http://ec2-3-70-200-33.eu-central-1.compute.amazonaws.com:3128"

# Tags
#CHANGE THIS
tags = {
  "Environment" = "Development"
  "customer_tag_1" = "placeholder1"
  "Owner" = "testuser@example.com"
  "customer_tag_2" = "placeholder2"
}

# Timing delays (in seconds) for sequential instance creation
delay_between_nodes = 300  # 5 minutes

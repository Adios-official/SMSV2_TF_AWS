variable "region" {
  description = "AWS region to launch the EC2 instances"
  type        = string
}

variable "ec2_instance_name_1" {
  description = "Name for the first EC2 instance"
  type        = string
}

variable "ec2_instance_name_2" {
  description = "Name for the second EC2 instance"
  type        = string
}

variable "ec2_instance_name_3" {
  description = "Name for the third EC2 instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id_1" {
  description = "Subnet ID for the first EC2 instance"
  type        = string
}

variable "subnet_id_2" {
  description = "Subnet ID for the second EC2 instance"
  type        = string
}

variable "subnet_id_3" {
  description = "Subnet ID for the third EC2 instance"
  type        = string
}

variable "az_name_1" {
  description = "Availability zone for the first EC2 instance"
  type        = string
}

variable "az_name_2" {
  description = "Availability zone for the second EC2 instance"
  type        = string
}

variable "az_name_3" {
  description = "Availability zone for the third EC2 instance"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "key_pair" {
  description = "Key pair name"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "ami" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "root_block_device" {
  description = "Block device configuration"
  type        = map(any)
}


variable "tags" {
  description = "Tags for EC2 instances"
  type        = map(string)
}

variable "delay_between_nodes" {
  description = "Delay between the creation of each node (in seconds)"
  type        = number
}

variable "cluster_name" {
  description = "Base name for the EC2 instances"
  type        = string
}

variable "token" {
  description = "Token to be used in the user data script"
  type        = string
}

variable "proxy" {
  description = "proxy to be used in the user data script"
  type        = string
}

# Other variables remain unchanged

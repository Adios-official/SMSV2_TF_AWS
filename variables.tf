################################################################################
# 1. F5 DISTRIBUTED CLOUD (XC) VARIABLES
################################################################################

variable "api_p12_file" {
  description = "Path to the F5 XC API credential file (PKCS12)"
  type        = string
}

variable "api_url" {
  description = "F5 XC API URL (e.g., 'https://<tenant>.console.ves.volterra.io/api')"
  type        = string
}

################################################################################
# 2. DEPLOYMENT MODEL & SITE VARIABLES
################################################################################

variable "deployment_model" {
  description = "The logical deployment model: 'cluster' (standard HA site) or 'vsite' (multiple independent sites grouped by a virtual_site)."
  type        = string
  default     = "cluster"

  validation {
    condition     = contains(["cluster", "vsite"], var.deployment_model)
    error_message = "The deployment_model must be either 'cluster' or 'vsite'."
  }
}

variable "cluster_name" {
  description = "Base name for the F5 XC site(s) and AWS resources. Must be a valid DNS-1035 label."
  type        = string

  validation {
    # This regex enforces DNS-1035 label requirements
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.cluster_name))
    error_message = "Invalid cluster_name: Must consist of lower case alphanumeric characters or '-', start with a letter, and end with an alphanumeric character."
  }
}

variable "num_nodes" {
  description = "Number of CE nodes to create. 'cluster' model supports 1 or 3. 'vsite' model supports 1, 2, or 3."
  type        = number
  # Validation for this is handled by a 'check' block in main.tf
  # as it depends on 'var.deployment_model'.
}

variable "num_nics" {
  description = "Number of network interfaces per node: 1 (SLO only) or 2 (SLO + SLI)."
  type        = number

  validation {
    condition     = contains([1, 2], var.num_nics)
    error_message = "The number of NICs must be either 1 or 2."
  }
}

################################################################################
# 3. AWS COMPUTE & IMAGE VARIABLES
################################################################################

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the CE nodes (e.g., 't3.xlarge')"
  type        = string
}

variable "ami" {
  description = "AMI ID for the F5 XC CE nodes"
  type        = string
}

variable "root_block_device" {
  description = "Root EBS volume configuration for each node."
  type = object({
    volume_size = number
    volume_type = string
    # 'encrypted' is set in tfvars but not explicitly typed here
    # to maintain flexibility with the provided tfvars structure.
  })
}

variable "key_pair" {
  description = "Name of the existing AWS EC2 Key Pair for SSH access"
  type        = string
}

variable "tags" {
  description = "A map of custom AWS tags to apply to all created resources"
  type        = map(string)
  default     = {}
}

################################################################################
# 4. AWS NETWORKING & SECURITY VARIABLES
################################################################################

variable "vpc_id" {
  description = "ID of the VPC where nodes will be deployed"
  type        = string
}

variable "az_names" {
  description = "List of Availability Zones. The number of AZs must match 'var.num_nodes'."
  type        = list(string)
  # Validation for count is handled by the resource 'count' parameter itself.
}

variable "slo_subnet_ids" {
  description = "List of Subnet IDs for the SLO (eth0) interface. Must match 'var.num_nodes'."
  type        = list(string)
}

variable "sli_subnet_ids" {
  description = "List of Subnet IDs for the SLI (eth1) interface. Only used if 'num_nics = 2'."
  type        = list(string)
  default     = [] # Default to empty list, as it's optional.
}

variable "public_ip_mode" {
  description = "Method for assigning Public IPs: 'CREATE_EIP', 'USE_EXISTING_EIP', or 'NONE'."
  type        = string
  default     = "CREATE_EIP"

  validation {
    condition     = contains(["CREATE_EIP", "USE_EXISTING_EIP", "NONE"], var.public_ip_mode)
    error_message = "public_ip_mode must be one of: 'CREATE_EIP', 'USE_EXISTING_EIP', or 'NONE'."
  }
}

variable "existing_eip_allocation_ids" {
  description = "List of existing EIP Allocation IDs. Only used if 'public_ip_mode = USE_EXISTING_EIP'."
  type        = list(string)
  default     = []
  # Validation for this is handled by a 'check' block in main.tf
  # as it depends on 'var.public_ip_mode' and 'var.num_nodes'.
}

variable "security_group_config" {
  description = "Configuration for SLO and SLI Security Groups."
  type = object({
    create_slo_sg      = bool
    create_sli_sg      = bool
    existing_slo_sg_id = string
    existing_sli_sg_id = string
  })
  # Validation for this is handled by a 'check' block in main.tf
  # as it depends on 'var.num_nics'.
}

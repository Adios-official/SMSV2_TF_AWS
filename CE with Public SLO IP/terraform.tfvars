##############################################################################################################################
# BLOCK 1 #  BASIC AWS VARIABLES
##############################################################################################################################
# AWS Region
# CHANGE THIS
region = "xxxxxxxxxx"

# VPC Information
# CHANGE THIS
vpc_id = "vpc-xxxxxxxxxx"


##############################################################################################################################
# BLOCK 2 #  BASIC VARIABLES FOR CE 
# AWS Instance Information - Resources required per node: Minimum 4 vCPUs, 14 GB RAM, and 80 GB disk storage
# CHANGE THESE VALUES AS PER YOUR USE-CASE
##############################################################################################################################

# CHANGE THIS
cluster_name = "adios-aws5-smsv2-3no-2ni"    # Name for the customer Edge ( Each node will take this name followed by suffix like node-1, node-2 etc. )
num_nodes           = 3                      # Choose if you need a Single Node CE or an HA CE with 3 Nodes
num_nics            = 1                      # Use 1 for single NIC or 2 for dual NIC. 
instance_type = "t3.xlarge"                  # # SMALL :t3.xlarge, Medium :t3.2xlarge, Large:m5.4xlarge
ami = "ami-0641366e54b020b08"                # Read "Find AMI" section from https://docs.cloud.f5.com/docs-v2/multi-cloud-network-connect/how-to/site-management/deploy-sms-aws-clickops
root_block_device = {                        # The root block device is the primary disk used to store the operating system and boot the instance.
  volume_size         = 80                   # Disk size in GB. 80 GB is minimum. (default size depends on the AMI, but you can override it).
  volume_type         = "gp2"                # Type of EBS volume (e.g., gp2 for General Purpose SSD, io1 for Provisioned IOPS SSD).
  encrypted           = false                # Whether the root volume is encrypted (default: false).
  }       
  key_pair            = "xxxxxxxxxx"         # This would be existing SSH key pair in AWS for Command line access to the nodes.
  tags = {                                   # Tags you would like to add to the nodes in the CE cluster. 
  "Environment"       = "Development"
  "customer_tag_1"    = "placeholder1"
  "Owner"             = "exampleuser@f5.com"
  "customer_tag_2"    = "placeholder2"
  }
  




##############################################################################################################################
# BLOCK 3 #  NETWORKING AND NETWORK INTERFACES FOR NODES
# 3.1 SLO CONFIG 
# Provide distinct SLO subnet values for each node if 3 nodes
##############################################################################################################################


# Subnet IDs (ensure these match the number of nodes if num_nodes = 3)
# Add your Subnet IDs here for SLO, 1 for each node in case of 3 nodes. For 1 node just 1 value is enough in the list.
# CHANGE THIS
slo_subnet_ids = [
  "subnet-xxxxxxxxxx", # For node-1
  "subnet-xxxxxxxxxx", # For node-2
  "subnet-xxxxxxxxxx"  # For node-3
]


##############################################################################################################################
# BLOCK 3 #  NETWORKING AND NETWORK INTERFACES FOR NODES
# 3.2 SLI CONFIG 
# VALUES ARE ONLY CONSUMED IF YOU NEED DUAL NIC AND YOU HAVE GIVEN num_nics = 2
# Provide distinct SLI subnet values for each node if 3 nodes
##############################################################################################################################

# Subnet IDs (ensure these match the number of nodes if num_nodes = 3)
# Add your Subnetwork/Subnet name here for SLI, 1 for each node in case of 3 nodes. For 1 node just 1 value is enough in the list.
# CHANGE THIS
sli_subnet_ids = [
  "subnet-xxxxxxxxxx", # For node-1
  "subnet-xxxxxxxxxx", # For node-2
  "subnet-xxxxxxxxxx"  # For node-3
]

##############################################################################################################################
# BLOCK 4 # PUBLIC IP ASSIGNMENT VARIABLES
##############################################################################################################################

# Elastic IP configuration (either create new EIPs or use existing ones)
# These are the Public Elastic IPs that would be then assigned to the SLO interface 
# If you don't want EIPs to be created by the code, you can use your existing EIPs by choosing create_eip as false and providing existing EIP Allocation IDs
# CHANGE THIS AS PER NEED
eip_config = {
  create_eip  = true
  existing_allocation_ids = [
    
    ]  # Leave empty if create_eip is true, otherwise provide existing EIP Allocation IDs
}


##############################################################################################################################
# BLOCK 5 # AVAILABILITY ZONE DETAILS
# Provide distinct Availability zone values for each node if 3 nodes
##############################################################################################################################
# Availability Zones (ensure these match the number of nodes if num_nodes = 3)
# CHANGE THIS
az_names = [
  "eu-central-1a", # For node-1
  "eu-central-1b", # For node-2
  "eu-central-1c"  # For node-3
]



##############################################################################################################################
# BLOCK 6 # SECURITY GROUP DETAILS
##############################################################################################################################

# Security group configuration (either create new Security groups or use existing ones)
# When you choose to create new Security groups , the code creates a security group which has an allow all policy.
# If you want to add further rules, you can add in main.tf or you add additional rules to the security group after the site provisioning is complete.
# CHANGE THIS AS PER NEED

security_group_config = {
  create_slo_sg     = true
  create_sli_sg     = true
  existing_slo_sg_id = ""    # Leave empty if create_slo_sg is true, otherwise provide existing Security group IDs for SLO interface
  existing_sli_sg_id = ""    # Leave empty if create_sli_sg is true, otherwise provide existing Security group  IDs for SLI interface
}


##############################################################################################################################
# BLOCK 7 # API CREDENTIAL DETAILS , TENANT DETAILS FROM DISTRIBUTED CLOUD
##############################################################################################################################

# These are arguments to supply your API credentials for interacting with the XC Tenant
# CHANGE THIS
api_p12_file = "xxxxxxxxxx.console.ves.volterra.io.api-creds.p12"
api_url      = "https://xxxxxxxxxx.console.ves.volterra.io/api"

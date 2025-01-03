Based on the provided files, here's a README that describes your Terraform configuration for deploying EC2 instances:

---

# EC2 Multi-Node Deployment using Terraform ( Fully Automated -  uses AWS Provider + XC(Volterra) provider )

This Terraform configuration deploys a set of three EC2 instances across different availability zones (AZs) within a Virtual Private Cloud (VPC) in AWS. Each EC2 instance is placed in its own subnet and AZ, and all instances are configured with user data scripts for provisioning upon startup.
Along with EC2 deployment, the code will also take care of spinning up SMSV2 Object in F5 Distributed cloud, generating the token and bringing up the site. This wouldbe a 0 touch deployment that is fully automated.
Note : This is for a brown field deployment scenario, where the VPC, Subnets, Route tables and Public IP assigment is already enabled at subent level or the instance is behind a NAT gateway. 

## Prerequisites

Before using this Terraform project, ensure you have the following:
- AWS Account
- AWS credentials configured in your environment (you can specify this in the `terraform.tfvars` file)
- Terraform installed on your machine
- AMI available for your region based on the steps from Distributed Cloud Portal (you can specify this in the `terraform.tfvars` file)
- Token Generated from Distributed Cloud Portal SMSV2 site object

## Files

### 1. `terraform.tfvars`

This file contains user-specific variables to be customized based on your environment. Key fields to modify:
- **AWS Region:** Specify your region (e.g., `eu-central-1`).
- **Cluster Name:** Base name for EC2 instances. Example: `adios-bugtest4-0911`.
- **VPC and Subnet IDs:** Provide the VPC and subnet IDs for the instances. Ensure each instance is in a different subnet.
- **Availability Zones:** Assign an AZ for each instance.
- **Security Group IDs:** Provide your security group ID.
- **Key Pair Name:** Specify the key pair for SSH access.
- **IAM Instance Profile:** Set the IAM instance profile for the EC2 instances.
- **AMI:** Provide the AMI ID to use for instance creation.
- **Tags:** You can customize the tags to include environment, owner, and other relevant information.
- **Proxy:** You can specify the proxy details in case you are using an enterprise proxy in the architecture. Else you can delete the field.
- **api_p12_file**  This would be the API credential file that you have generated (e.g., `yourtenant-xdwfuiw.console.ves.volterra.io.api-creds.p12`).
- **api_url** This would be the API URL for terraform to interact with your tenant (e.g., `https://yourtenant-xdwfuiw.console.ves.volterra.io/api`).

```hcl
region               = "eu-central-1"
cluster_name         = "adios-bugtest4-0911"
vpc_id               = "vpc-xxxxxxxxxxxxxxxxx"
subnet_id_1          = "subnet-xxxxxxxxxxxxxxxxx"
subnet_id_2          = "subnet-xxxxxxxxxxxxxxxxx"
subnet_id_3          = "subnet-xxxxxxxxxxxxxxxxx"
az_name_1            = "eu-central-1a"
az_name_2            = "eu-central-1b"
az_name_3            = "eu-central-1c"
security_group_ids   = ["sg-xxxxxxxxxxxxxxxxx"]
key_pair             = "sample_key_pair"
instance_profile_name= "xxxxxxxxxx"
ami                  = "ami-0d43e733ea176527a"
instance_type        = "t3.xlarge"
root_block_device    = { volume_size = 80 }
token                = "xxxxxxxxxxxxxx"
proxy                = "http://ec2-4-90-499-23.eu-central-1.compute.amazonaws.com:3128"
tags = {
  "Environment"      = "Development"
  "Owner"            = "testuser@example.com"
}
api_p12_file         = "sdc-support.console.ves.volterra.io.api-creds.p12"
api_url              = "https://sdc-support.console.ves.volterra.io/api"
```

### 2. `variables.tf`

This file defines the variables used across the Terraform configuration. These variables are customizable and can be modified in the `terraform.tfvars` file.

Key variables include:
- AWS region, VPC, and subnets
- Security groups, key pairs, and IAM instance profiles
- EC2 instance details (e.g., instance type, AMI, block device configuration)
- User data for provisioning EC2 instances
- Delays between instance creation to ensure sequential startup. Currently this part of the code is commented out in main.tf. Uncommment to use this function.

### 3. `main.tf`

This is the main Terraform configuration file, which defines the resources to be created. The configuration includes three EC2 instances, each with the following settings:
- **AMI and Instance Type:** Set based on provided variables.
- **Availability Zone and Subnet:** Each instance is deployed in its own subnet and AZ.
- **Security Group:** Security groups are applied to manage access.
- **Root Block Device:** Each instance has a root block device of 80GB.
- **User Data:** The user data script initializes each instance by writing the token (and proxy, if needed) to `/etc/vpm/user_data`.
- **Tags:** Instances are tagged based on cluster name, node identifier, and other custom tags.
- **Sequential Creation:** Instances can also be created sequentially, with a delay between each one to ensure proper startup. Currently this part of the code is commented out. Uncommment to use this function.

## How to Use

1. **Initialize Terraform**  
   Run the following command to initialize the working directory containing the configuration files:
   ```bash
   terraform init
   ```

2. **Plan the Deployment**  
   To see the resources that Terraform will create, run:
   ```bash
   terraform plan
   ```

3. **Apply the Configuration**  
   Deploy the instances by applying the configuration:
   ```bash
   terraform apply
   ```

4. **Destroy Resources**  
   To tear down the infrastructure, use:
   ```bash
   terraform destroy
   ```

## Customization

- **Token and Proxy:** Ensure that the token for user data is generated from the XC console and included in `terraform.tfvars`. The proxy can be deleted if not required.
- **Tags:** Modify the tags in the `terraform.tfvars` file to reflect the correct environment and owner information.
- **Delays Between Nodes:** You can adjust the delay between creating each instance by modifying the `delay_between_nodes` variable.

## Conclusion

This Terraform project provides an easy way to deploy three EC2 instances across different subnets and availability zones, with user data scripts for initialization. Customize the variables as needed for your environment and deploy your EC2 instances with ease.

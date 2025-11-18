################################################################################
# OUTPUTS
################################################################################
output "deployment_summary" {
  description = "A structured summary of all deployed resources and their key information."
  
  value = {
    # 1. Summary of inputs
    deployment_model = var.deployment_model
    cluster_name     = var.cluster_name
    node_count       = var.num_nodes
    nic_count        = var.num_nics
    public_ip_mode   = var.public_ip_mode
    aws_region       = var.region

    # 2. AWS Compute outputs
    aws_instance_ids = [for instance in aws_instance.ec2_instance : instance.id]
    aws_instance_azs = [for instance in aws_instance.ec2_instance : instance.availability_zone]

    # 3. AWS Networking outputs
    # Public IPs (SLO)
    public_ips_slo = var.public_ip_mode == "CREATE_EIP" ? tolist([for eip in aws_eip.example : eip.public_ip]) : (
                       var.public_ip_mode == "USE_EXISTING_EIP" ? tolist([for alloc_id in var.existing_eip_allocation_ids : data.aws_eip.lookup[alloc_id].public_ip]) : []
                     )
    
    # Private IPs (SLO)
    private_ips_slo = [for nic in aws_network_interface.slo_nics : nic.private_ip]
    
    # Private IPs (SLI - only included if nic_count is 2)
    private_ips_sli = var.num_nics == 2 ? [for nic in aws_network_interface.sli_nics : nic.private_ip] : []
    
    created_security_groups = {
      slo = try(aws_security_group.slo_sg[0].id, null)
      sli = try(aws_security_group.sli_sg[0].id, null)
    }

    # 4. F5 XC outputs
    f5_xc_site_names = [for site in volterra_securemesh_site_v2.smsv2-site-object : site.name]
    f5_xc_virtual_site_name = (
      var.deployment_model == "vsite" ? try(volterra_virtual_site.smsv2-vsite[0].name, null) : "N/A (Cluster Model)"
    )
  }
}

# Data resource to fetch public IPs for existing allocation IDs
# NOTE: This data source must remain in the file as it's required for the
# public_ips_slo calculation above when public_ip_mode is set to "USE_EXISTING_EIP".
data "aws_eip" "lookup" {
  for_each = var.public_ip_mode == "USE_EXISTING_EIP" ? toset(var.existing_eip_allocation_ids) : []

  # Look up the EIP by its allocation_id, which is passed to the 'id' argument
  id = each.value
}

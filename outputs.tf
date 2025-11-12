#########################################################################################################
# OUTPUT OF PUBLIC IPs Allocated to SLO
#########################################################################################################
output "allocated_public_ips_to_SLO" {
  description = "List of public IPs allocated to the instances. Will be empty if public_ip_mode is 'NONE'."
  
  # This value expression is now a nested conditional:
  # 1. If "CREATE_EIP", get IPs from the 'aws_eip' resource.
  # 2. Else if "USE_EXISTING_EIP", get IPs from the 'data.aws_eip.lookup'.
  # 3. Else ("NONE"), return an empty list [].
  value = var.public_ip_mode == "CREATE_EIP" ? [for eip in aws_eip.example : eip.public_ip] : (
            var.public_ip_mode == "USE_EXISTING_EIP" ? [for alloc_id in var.existing_eip_allocation_ids : data.aws_eip.lookup[alloc_id].public_ip] : []
          )
}

# Data resource to fetch public IPs for existing allocation IDs
data "aws_eip" "lookup" {
  # This now only runs if the mode is "USE_EXISTING_EIP"
  for_each = var.public_ip_mode == "USE_EXISTING_EIP" ? toset(var.existing_eip_allocation_ids) : []

  # Look up the EIP by its allocation_id, which is passed to the 'id' argument
  id = each.value
}

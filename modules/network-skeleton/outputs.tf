output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main_vpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = aws_vpc.main_vpc.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by availability zone."
  value       = { for az, subnet in aws_subnet.public_subnets : az => subnet.id }
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by availability zone."
  value       = { for az, subnet in aws_subnet.private_subents : az => subnet.id }
}

output "first_public_subnet_id" {
  description = "First public subnet ID."
  value       = aws_subnet.public_subnets[local.azs[0]].id
}

output "first_private_subnet_id" {
  description = "First private subnet ID."
  value       = aws_subnet.private_subents[local.azs[0]].id
}

output "first_az" {
  description = "First availability zone."
  value       = local.azs[0]
}

output "azs" {
  description = "Availability zones in use."
  value       = local.azs
}

output "private_subnet_map" {
  description = "Private subnet details keyed by availability zone."
  value = {
    for az, subnet in aws_subnet.private_subents : az => {
      id    = subnet.id
      az    = az
      index = local.private_subnets[az].index
    }
  }
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = aws_internet_gateway.internet_gateway.id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs keyed by availability zone."
  value       = { for az, nat in aws_nat_gateway.this : az => nat.id }
}

output "nodes_nacl_id" {
  description = "Network ACL ID associated with the private/node subnets."
  value       = var.enable_nodes_nacl ? aws_network_acl.nodes[0].id : null
}

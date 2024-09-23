# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "name" {
  value = aws_vpc.main.tags["Name"]
}

output "cidr_block" {
  description = "The cidr_block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "The ID of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "The ID of the private subnets."
  value       = aws_subnet.private[*].id
}

output "private_subnets" {
  description = "The private subnets."
  value = [
    for subnet in aws_subnet.private : {
      id                   = subnet.id
      cidr_block           = subnet.cidr_block
      availability_zone    = subnet.availability_zone
      availability_zone_id = subnet.availability_zone_id
    }
  ]
}

output "main_route_table_id" {
  description = "The ID of the main route table."
  value       = aws_vpc.main.main_route_table_id
}

output "public_subnets_route_table_id" {
  description = "The ID of the routing table for the public subnets."
  value       = concat(aws_route_table.public[*].id, [""])[0]
}

output "public_subnets_route_table_ids" {
  description = "The IDs of the routing table for the public subnets."
  value       = aws_route_table.public[*].id
}

output "private_subnets_route_table_ids" {
  description = "The IDs of the routing tables for the private subnets."
  value       = aws_route_table.private[*].id
}

output "nat_gateway_ids" {
  description = "The IDs of the NAT Gateways."
  value       = aws_nat_gateway.private[*].id
}

output "default_security_group_id" {
  description = "The id of the VPC default security group"
  value       = aws_vpc.main.default_security_group_id
}

output "default_network_acl_id" {
  description = "The ID of the network ACL created by default on VPC creation"
  value       = aws_vpc.main.default_network_acl_id
}

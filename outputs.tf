# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC."
  value       = "${aws_vpc.main.id}"
}

output "public_subnet_ids" {
  description = "The ID of the public subnets."
  value       = "${aws_subnet.public.*.id}"
}

output "private_subnet_ids" {
  description = "The ID of the private subnets."
  value       = "${aws_subnet.private.*.id}"
}

output "public_subnets_route_table_id" {
  description = "The ID of the routing table for the public subnets."
  value       = "${aws_route_table.public.id}"
}

output "private_subnets_route_table_ids" {
  description = "The IDs of the routing tables for the private subnets."
  value       = "${aws_route_table.private.*.id}"
}

output "main_route_table_id" {
  description = "The ID of the main route table."
  value       = "${aws_vpc.main.main_route_table_id}"
}

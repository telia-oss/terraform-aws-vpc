# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
}

variable "cidr_block" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "create_nat_gateways" {
  description = "If this is set to false NAT gateways (which cost $) will not be created and the private subnets will only route trafffic to the internet via the egress only gateway(no cost) - Egress only gateways only work for IPv6)"
  default     = "true"
}

variable "enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC."
  default     = "false"
}

variable "private_subnet_count" {
  description = "Number of private subnets to provision (will not exceed the number of AZ's in the region)."
  default     = "0"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = "map"
  default     = {}
}

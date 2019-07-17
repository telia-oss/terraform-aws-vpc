# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "The availability zones to use for the subnets."
  type        = list(string)
  default     = []
}

variable "create_public_subnets" {
  description = "Flag to create public subnets."
  type        = bool
  default     = true
}

variable "create_private_subnets" {
  description = "Flag to create private subnets."
  type        = bool
  default     = false
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks to use for the public subnets."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks to use for the private subnets."
  type        = list(string)
  default     = []
}

variable "create_nat_gateways" {
  description = "If this is set to false NAT gateways (which cost $) will not be created and the private subnets will only route trafffic to the internet via the egress only gateway(no cost) - Egress only gateways only work for IPv6)"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}


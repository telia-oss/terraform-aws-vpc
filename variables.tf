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
  description = "The availability zones to use for subnets and resources in the VPC. By default, all AZs in the region will be used."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks to use for the public subnets. When null, creates a single /20-prefixed subnet per AZ."
  type        = list(string)
  default     = null
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks to use for the private subnets."
  type        = list(string)
  default     = []
}

variable "create_nat_gateways" {
  description = "Optionally create NAT gateways (which cost $) to provide internet connectivity to the private subnets."
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


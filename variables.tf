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
}

variable "availability_zones" {
  description = "The availability zones to use for subnets and resources in the VPC. By default, all AZs in the region will be used."
  type        = list(string)
  default     = []
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

variable "ipv6_public_subnet_netnum_offset" {
  description = "By default public IPv6 subnets is allocated from start of VPC IPv6 CIDR block. This can be used to force an offset, i.e. if adding public subnets when private ones already exists (which would be at beginning of block)."
  type        = number
  default     = 0
}

variable "ipv6_private_subnet_netnum_offset" {
  description = "By default private IPv6 subnet is allocated directly after last public subnet. This can be used to force an offset."
  type        = number
  default     = -1
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

variable "s3_endpoint_policy" {
  description = "Policy document to attach to S3 Gateway Endpoint. Defaults to blank."
  default     = null
}

variable "dynamodb_endpoint_policy" {
  description = "Policy document to attach to DynamoDb Gateway Endpoint. Defaults to blank."
  default     = null
}

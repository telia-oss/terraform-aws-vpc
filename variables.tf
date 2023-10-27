# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "ipam_subnet_newbits" {
  type        = number
  description = "newbits is the number of additional bits with which to extend the prefix. For example: 1) If var.vpc_netmask_ipam is 25 and a var.ipam_subnet_newbits is 2, the subnet addresses be /27. This is usually used for 'on-prem' IPAM pools with 3 subnets. 2) If var.vpc_netmask_ipam is 24 and a var.ipam_subnet_newbits is 3, the subnet addresses be /27. This is usually used for 'cloud-only' IPAM pools with 6 subnets."
  default     = "3"
}

variable "vpc_netmask_ipam" {
  type        = number
  description = "The netmask to ask for from IPAM for your VPC"
  default     = 25
}

variable "ipam_pool" {
  description = "The IPAM pool to use for the VPCs primary CIDR"
  type        = string
  default     = null
  validation {
    condition     = var.ipam_pool == null || can(regex("^(cloud-only|on-prem)?$", var.ipam_pool))
    error_message = "The ipam_pool value must be one of: cloud-only, on-prem or null(empty)."
  }
}

variable "cidr_block" {
  description = "The CIDR block for the VPC. Use if you want to explicity set your CIDR and don't get CIDR from IPAM."
  type        = string
  default     = null
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks to use for the public subnets. Use if you want to explicity set your CIDR and don't get CIDR from IPAM."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks to use for the private subnets. Use if you want to explicity set your CIDR and don't get CIDR from IPAM."
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "The availability zones to use for subnets and resources in the VPC. By default, all AZs in the region will be used."
  type        = list(string)
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is true."
  type        = bool
  default     = true
}

variable "create_nat_gateways" {
  description = "Optionally create NAT gateways (which cost $) to provide internet connectivity to the private subnets."
  type        = bool
  default     = true
}

variable "create_internet_gateway" {
  description = "Optionaly create an Internet Gateway resource"
  type        = bool
  default     = true
}

variable "create_egress_only_internet_gateway" {
  description = "Optionaly create an Egress Only Internet Gateway resource"
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


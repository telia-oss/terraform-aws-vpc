# AWS VPC Terraform Module

This Terraform module provisions a fully featured VPC on AWS, supporting both IPv4 and IPv6, public and private subnets, NAT gateways, route tables, and more.

## Main Features

- Supports both IPv4 and IPv6
- Provisions public and private subnets
- Optional NAT gateways for outbound internet connectivity
- Configurable internet and egress-only gateways
- Route tables and associations
- IPAM integration for dynamic CIDR allocation

## Usage

```hcl
module "vpc" {
  source                              = ""../..""
  name_prefix                         = "vpc_name"
  create_nat_gateways                 = true
  create_internet_gateway             = true
  create_egress_only_internet_gateway = true
  ipam_pool                           = "cloud-only"
  vpc_netmask_ipam                    = 24
  tags                                = { Environment = "dev" }
  ...
}
```
## Inputs

### Core Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `name_prefix` | A prefix used for naming resources. | `string` | `-` |
| `cidr_block` | The CIDR block for the VPC. If not set, it will get CIDR from IPAM. | `string` | `null` |
| `public_subnet_cidrs` | List of CIDR blocks for public subnets. If not provided, relies on IPAM. | `list(string)` | `[]` |
| `private_subnet_cidrs` | List of CIDR blocks for private subnets. If not provided, relies on IPAM. | `list(string)` | `[]` |
| `availability_zones` | Availability zones to use for subnets and resources. Uses all AZs in the region by default. | `list(string)` | `[]` |
| `map_public_ip_on_launch` | Whether instances in the subnet receive public IP addresses. | `bool` | `true` |
| `create_nat_gateways` | Whether to create NAT gateways. | `bool` | `true` |
| `create_internet_gateway` | Whether to create an internet gateway. | `bool` | `true` |
| `create_egress_only_internet_gateway` | Whether to create an egress-only internet gateway. | `bool` | `true` |
| `enable_dns_hostnames` | Enable/disable DNS hostnames in the VPC. | `bool` | `false` |
| `tags` | A map of tags to add to all resources. | `map(string)` | `{}` |

## IPAM-Related Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ipam_subnet_newbits` | Number of additional bits with which to extend the prefix. See variable description for details. | `number` | `3` |
| `vpc_netmask_ipam` | The netmask to request from IPAM for your VPC. | `number` | `25` |
| `ipam_pool` | The IPAM pool to use for the VPC's primary CIDR. | `string` | `null` |

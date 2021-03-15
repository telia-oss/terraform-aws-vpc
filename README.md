## VPC

[![workflow](https://github.com/telia-oss/terraform-aws-vpc/workflows/workflow/badge.svg)](https://github.com/telia-oss/terraform-aws-vpc/actions)

This is a module which simplifies setting up a new VPC and getting it into a useful state:

- Sets up the route tables for the public and private subnets you specify.
- Enables IPv6 for the VPC and allocates a /64 block for each of the public and private subnets.
- Creates up an internet gateway and route table for your public subnets.
- Creates a NAT gateway for your private subnets if desired (requires public subnets).
- Creates an egress only internet gateway for IPv6 traffic outbound from the private subnets.
- Adds the tag `type` to each subnet with the value of either `public` or `private`.
- Adds VPC Gateway Endpoints for s3 and dynamodb

Note that, if `create_nat_gateways` is enabled, each private subnet has a route table which targets an individual NAT gateway when accessing
the internet over IPv4, which means that all instances in a given private subnet will appear to have the same static IP from the outside.

Note: if you already have a VPC setup with private subnets, and later add public subnets, your private subnet needs to be recreated due to how this module originally assigned IPv6 addresses.
This can be avoided by setting the variables `ipv6_private_subnet_netnum_offset = 0` & `ipv6_public_subnet_netnum_offset = 128` which will force private subnets to still be allocated from 0, and public subnets from an offset.
The maximum value of subnets in a IPv6 CIDR block is 255, we get a /56 from AWS and we divide them into /64 which gives us 8 bits for subnets. Hence 128 will allow 128 private subnets, and 128 public ones.

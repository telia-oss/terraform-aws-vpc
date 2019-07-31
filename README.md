## VPC

[![Build Status](https://travis-ci.com/telia-oss/terraform-aws-vpc.svg?branch=master)](https://travis-ci.com/telia-oss/terraform-aws-vpc)

This is a module which simplifies setting up a new VPC and getting it into a useful state:

- Sets up the route tables for the public and private subnets you specify.
- Enables IPv6 for the VPC and allocates a /64 block for each of the public and private subnets.
- Creates up an internet gateway and route table for your public subnets.
- Creates a NAT gateway for your private subnets if desired (requires public subnets).
- Creates an egress only internet gateway for IPv6 traffic outbound from the private subnets.
- Adds the tag `type` to each subnet with the value of either `public` or `private`.

Note that, if `create_nat_gateways` is enabled, each private subnet has a route table which targets an individual NAT gateway when accessing
the internet over IPv4, which means that all instances in a given private subnet will appear to have the same static IP from the outside.

## VPC

[![Build Status](https://travis-ci.com/telia-oss/terraform-aws-vpc.svg?branch=master)](https://travis-ci.com/telia-oss/terraform-aws-vpc)

This is a module which simplifies setting up a new VPC and getting it into a useful state:

- Creates one public subnet per availability zone (with a shared route table and internet gateway).
- Creates the desired number of private subnets (with one NAT gateway and route table per subnet).
- Creates an egress only internet gateway for IPv6 traffic outbound from the private subnets
- Evenly splits the specified IPv4 CIDR block between public/private subnets.
- Adds the tag `type` to each subnet with the value of either `public` or `private`.

Note that, if `create_nat_gateways` is enabled, each private subnet has a route table which targets an individual NAT gateway when accessing
the internet over IPv4, which means that all instances in a given private subnet will appear to have the same static IP from the outside.

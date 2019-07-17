terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = ">= 2.17"
  region  = "${var.region}"
}

module "vpc" {
  source      = "../../"
  name_prefix = var.name_prefix
  cidr_block  = "10.100.0.0/16"

  availability_zones = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c",
  ]

  create_private_subnets = true
  private_subnet_cidrs = [
    "10.100.48.0/20",
    "10.100.64.0/20",
  ]

  create_nat_gateways  = true
  enable_dns_hostnames = true

  tags = {
    terraform   = "True"
    environment = "dev"
  }
}

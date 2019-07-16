terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = ">= 2.17"
  region  = "${var.region}"
}

module "vpc" {
  source               = "../../"
  name_prefix          = var.name_prefix
  cidr_block           = "10.100.0.0/16"
  create_nat_gateways  = true
  enable_dns_hostnames = true
  private_subnet_count = 2

  tags = {
    terraform   = "True"
    environment = "dev"
  }
}

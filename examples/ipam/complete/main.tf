terraform {
  required_version = ">= 0.14"
}

provider "aws" {
  #version = ">= 3.27" ##This is moved to required_providers block on TF 0.14
  region = var.region
}

module "ipam_vpc" {
  source                              = "../../terraform-aws-vpc"
  name_prefix                         = "cloud-only"
  create_nat_gateways                 = true
  create_internet_gateway             = true
  create_egress_only_internet_gateway = true
  ipam_pool                           = "cloud-only"
  vpc_netmask_ipam                    = 24


  tags = {
    terraform   = "True"
    environment = "dev"
  }
}

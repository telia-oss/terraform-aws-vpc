terraform {
  required_version = ">= 0.14"
}

provider "aws" {
  #version = ">= 3.27" ##This is moved to required_providers block on TF 0.14
  region = var.region
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

  public_subnet_cidrs = [
    "10.100.0.0/20",
    "10.100.16.0/20",
    "10.100.32.0/20",
  ]

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

  public_subnet_tags = {
    Type                               = "public"
    "kubernetes.io/role/elb"           = "1"
    "kubernetes.io/cluster/my-cluster" = "shared"
  }

  private_subnet_tags = {
    Type                               = "private"
    "kubernetes.io/role/internal-elb"  = "1"
    "kubernetes.io/cluster/my-cluster" = "shared"
    DatabaseTier                       = "true"
  }
}

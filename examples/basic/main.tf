terraform {
  required_version = ">= 0.14"
}

provider "aws" {
  #version = ">= 3.27" This is moved into required_providers block on TF 0.14
  region  = var.region
}

module "vpc" {
  source      = "../../"
  name_prefix = var.name_prefix
  cidr_block  = "10.0.0.0/24"

  public_subnet_cidrs = [
    "10.0.0.0/26",
    "10.0.0.64/26",
    "10.0.0.128/26",
  ]

  tags = {
    terraform   = "True"
    environment = "dev"
  }
}

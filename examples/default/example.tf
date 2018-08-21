provider "aws" {
  region = "us-west-2"
}

module "vpc1" {
  source               = "../../"
  name_prefix          = "example1"
  cidr_block           = "10.8.0.0/16"
  private_subnet_count = "2"
  create_public_subnets = "false"

  enable_dns_hostnames = "true"

  tags {
    environment = "prod"
    terraform   = "True"
  }
}

module "vpc2" {
  source               = "../../"
  name_prefix          = "example2"
  cidr_block           = "10.9.0.0/16"
  private_subnet_count = "3"
  create_public_subnets = "true"

  enable_dns_hostnames = "true"

  tags {
    environment = "prod"
    terraform   = "True"
  }
}
output "vpc_id1" {
  value = "${module.vpc1.vpc_id}"
}

output "vpc_id2" {
  value = "${module.vpc2.vpc_id}"
}

output "public_subnet_ids" {
  value = "${module.vpc1.public_subnet_ids}"
}

output "private_subnet_ids" {
  value = "${module.vpc2.private_subnet_ids}"
}

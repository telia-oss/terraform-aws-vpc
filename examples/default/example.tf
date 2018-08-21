provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source               = "../../"
  name_prefix          = "example"
  cidr_block           = "10.8.0.0/16"
  private_subnet_count = "2"
  create_public_subnets = "false"

  enable_dns_hostnames = "true"

  tags {
    environment = "prod"
    terraform   = "True"
  }
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "subnet_ids" {
  value = "${module.vpc.public_subnet_ids}"
}

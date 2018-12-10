provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source               = "../../../"
  name_prefix          = "test-no-nat"
  private_subnet_count = "3"
  create_nat_gateways = "false"
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "subnet_ids" {
  value = "${module.vpc.public_subnet_ids}"
}
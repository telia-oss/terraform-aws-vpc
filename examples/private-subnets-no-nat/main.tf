terraform {
  required_version = ">= 0.12"

  backend "s3" {
    key            = "terraform-modules/development/terraform-aws-vpc/private-subnets-no-nat.tfstate"
    bucket         = "<test-account-id>-terraform-state"
    dynamodb_table = "<test-account-id>-terraform-state"
    acl            = "bucket-owner-full-control"
    encrypt        = "true"
    kms_key_id     = "<kms-key-id>"
    region         = "eu-west-1"
  }
}

provider "aws" {
  version             = ">= 2.17"
  region              = "eu-west-1"
  allowed_account_ids = ["<test-account-id>"]
}

module "vpc" {
  source               = "../../"
  name_prefix          = "vpc-test-no-nat"
  private_subnet_count = "3"
  create_nat_gateways  = "false"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = module.vpc.public_subnet_ids
}


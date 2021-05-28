provider "aws" {
  region = var.region
}

data "aws_availability_zones" "main" {}

locals {
  vpc_cidr_block = "10.100.0.0/16"
  public_cidr_blocks = [for k, v in data.aws_availability_zones.main.names :
  cidrsubnet(local.vpc_cidr_block, 4, k)]
  private_cidr_blocks = [for k, v in data.aws_availability_zones.main.zone_ids :
  cidrsubnet(local.vpc_cidr_block, 4, k + length(data.aws_availability_zones.main.names))]
  tags = {
    terraform   = "true"
    environmemt = "dev"
  }
}

module "vpc" {
  source               = "../../"
  name_prefix          = var.name_prefix
  cidr_block           = local.vpc_cidr_block
  availability_zones   = data.aws_availability_zones.main.names
  private_subnet_cidrs = local.private_cidr_blocks
  create_nat_gateways  = false
  enable_dns_hostnames = true
  tags                 = local.tags
}

resource "aws_vpc_endpoint" "ssm" {
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = compact(concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids))
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.vpc.default_security_group_id]
  tags                = local.tags
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = compact(concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids))
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.vpc.default_security_group_id]
  tags                = local.tags
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2" {
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = compact(concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids))
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.vpc.default_security_group_id]
  tags                = local.tags
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = compact(concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids))
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.vpc.default_security_group_id]
  tags                = local.tags
  private_dns_enabled = true
}

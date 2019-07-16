terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = ">= 2.17"
  region  = "${var.region}"
}

module "vpc" {
  source      = "../../"
  name_prefix = "${var.name_prefix}"

  tags = {
    terraform   = "True"
    environment = "dev"
  }
}

provider "aws" {
  region   = "eu-north-1"
  alias = "eu-north-1_ipam"
}

provider "aws" {
  region   = "eu-west-1"
  alias = "eu-west-1_ipam"
}

data "aws_region" "current" {}

#Fetch stockholm pool information from IPAM
data "aws_vpc_ipam_pool" "eu-north-1_on_prem" { 
  filter {
    name   = "description"
    values = ["allows connection with on-prem capability using the IPAM pool in eu-north-1"] 
  }
  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
  provider = aws.eu-north-1_ipam
}

data "aws_vpc_ipam_pool" "eu-north-1_cloud_only" {
  filter {
    name   = "description"
    values = ["allows connection with cloud-only capability using the IPAM pool in eu-north-1"]
  }
  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
  provider = aws.eu-north-1_ipam
}

#Fetch Ireland pool information from IPAM
data "aws_vpc_ipam_pool" "eu-west-1_on_prem" { 
  filter {
    name   = "description"
    values = ["allows connection with on-prem capability using the IPAM pool in eu-west-1"]    
  }
  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
  provider = aws.eu-west-1_ipam
}

data "aws_vpc_ipam_pool" "eu-west-1_cloud_only" { 
  filter {
    name   = "description"
    values = ["allows connection with cloud-only capability using the IPAM pool in eu-west-1"]
  }
  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
  provider = aws.eu-west-1_ipam
}

locals {
  #Map ipam pools with their respective regions
  ipam_pools = {
    eu-north-1 = {
      on-prem = data.aws_vpc_ipam_pool.eu-north-1_on_prem.id 
      cloud-only = data.aws_vpc_ipam_pool.eu-north-1_cloud_only.id 
    }
    eu-west-1 = {
      on-prem = data.aws_vpc_ipam_pool.eu-west-1_on_prem.id 
      cloud-only = data.aws_vpc_ipam_pool.eu-west-1_cloud_only.id 
    }
  }

} 


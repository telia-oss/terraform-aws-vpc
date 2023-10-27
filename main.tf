# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
data "aws_availability_zones" "main" {}

data "aws_vpc" "cidr" {
  id = aws_vpc.main.id
}

locals {
  azs                                = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.main.names
  nat_gateway_count                  = var.create_nat_gateways && (length(var.public_subnet_cidrs) > 0 || (var.ipam_pool != "" && var.ipam_pool == "cloud-only")) ? length(local.azs) : 0
  internet_gateway_count             = var.create_internet_gateway && (length(var.public_subnet_cidrs) > 0 || (var.ipam_pool != "" && var.ipam_pool == "cloud-only")) ? 1 : 0
  public_subnet_count                = var.create_nat_gateways && (length(var.public_subnet_cidrs) > 0 || (var.ipam_pool != "" && var.ipam_pool == "cloud-only")) ? length(local.azs) : 0
  egress_only_internet_gateway_count = var.create_egress_only_internet_gateway && (length(var.private_subnet_cidrs) > 0 || (var.ipam_pool != "" && var.ipam_pool == "cloud-only")) ? 1 : 0

}
module "ipam" {

  source    = "./modules/ipam"
  ipam_pool = var.ipam_pool
}
#Runs if var.cidr_block is set
resource "aws_vpc" "main" {
  cidr_block                       = var.cidr_block
  ipv4_ipam_pool_id                = var.ipam_pool == null ? null : module.ipam.ipv4_ipam_pool_id #Used by IPAM
  ipv4_netmask_length              = var.cidr_block != null ? null : var.vpc_netmask_ipam         #Used by IPAM 
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = var.enable_dns_hostnames
  assign_generated_ipv6_cidr_block = true

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-vpc"
    },
    var.ipam_pool == null ? {} :
    {
      format("ipam-pool:%s", var.ipam_pool) = "true"
      "ipam-pool"                           = var.ipam_pool
    },
  )
}

resource "aws_internet_gateway" "public" {
  count  = local.internet_gateway_count
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-public-igw"
    },
  )
}

resource "aws_egress_only_internet_gateway" "outbound" {
  count  = local.egress_only_internet_gateway_count
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-egress-igw"
    },
  )
}

resource "aws_route_table" "public" {
  count  = local.public_subnet_count
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-public-rt-${count.index + 1}"
    },
  )
}


resource "aws_route" "public" {
  count = local.public_subnet_count
  depends_on = [
    aws_internet_gateway.public,
    aws_route_table.public,
  ]
  route_table_id         = aws_route_table.public[count.index].id
  gateway_id             = aws_internet_gateway.public[0].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "ipv6-public" {
  count = local.internet_gateway_count
  depends_on = [
    aws_internet_gateway.public,
    aws_route_table.public,
  ]
  route_table_id              = aws_route_table.public[count.index].id
  gateway_id                  = aws_internet_gateway.public[0].id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_subnet" "public" {
  count                           = length(var.public_subnet_cidrs) > 0 ? length(var.public_subnet_cidrs) : var.ipam_pool != "cloud-only" ? 0 : length(local.azs)
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs[count.index] : cidrsubnet(data.aws_vpc.cidr.cidr_block, var.ipam_subnet_newbits, length(local.azs) + count.index)
   ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, length(local.azs) + count.index)
  availability_zone               = element(local.azs, count.index)
  map_public_ip_on_launch         = var.map_public_ip_on_launch
  assign_ipv6_address_on_creation = true

  lifecycle {

    ignore_changes = [ipv6_cidr_block]

  }
  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-public-subnet-${count.index + 1}"
      "Tier" = "Public"
    },
    var.ipam_pool == null ? {} :
    {
      format("ipam-pool:%s", var.ipam_pool) = "true"
      "ipam-pool"                           = var.ipam_pool
    },
  )
}

resource "aws_route_table_association" "public" {
  count          = local.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = var.ipam_pool == null ? aws_route_table.public[0].id : aws_route_table.public[count.index].id
}

resource "aws_eip" "private" {
  count = local.nat_gateway_count
  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-nat-gateway-${count.index + 1}"
    },
  )
}

resource "aws_nat_gateway" "private" {
  depends_on = [
    aws_internet_gateway.public,
    aws_eip.private,
  ]
  count         = local.nat_gateway_count
  allocation_id = aws_eip.private[count.index].id
  subnet_id     = element(aws_subnet.public[*].id, count.index)

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-nat-gateway-${count.index + 1}"
    },
  )
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs) > 0 ? length(var.private_subnet_cidrs) : length(local.azs)
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-private-rt-${count.index + 1}"
    },
  )
}

resource "aws_route" "private" {
  depends_on = [
    aws_nat_gateway.private,
    aws_route_table.private,
  ]
  count                  = local.nat_gateway_count
  route_table_id         = aws_route_table.private[count.index].id
  nat_gateway_id         = element(aws_nat_gateway.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "ipv6-private" {
  depends_on = [
    aws_egress_only_internet_gateway.outbound,
    aws_route_table.private,
  ]
  count                       = local.egress_only_internet_gateway_count
  route_table_id              = aws_route_table.private[count.index].id
  egress_only_gateway_id      = aws_egress_only_internet_gateway.outbound[0].id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_subnet" "private" {
  count                           = length(var.private_subnet_cidrs) > 0 ? length(var.private_subnet_cidrs) : length(local.azs) #If subnet cidrs is explicity set we use these. If not we rely on IPAM to privision a CIDR for each AZ in the region.
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs[count.index] : cidrsubnet(data.aws_vpc.cidr.cidr_block, var.ipam_subnet_newbits,  count.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)
  availability_zone               = element(local.azs, count.index)
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = true

  lifecycle {
    ignore_changes = [ipv6_cidr_block]


  }
  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-private-subnet-${count.index + 1}"
      "Tier" = "Private"
    },
    var.ipam_pool == null ? {} :
    {
      format("ipam-pool:%s", var.ipam_pool) = "true"
      "ipam-pool"                           = var.ipam_pool
    },
  )
}


resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs) > 0 ? length(var.private_subnet_cidrs) : length(local.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


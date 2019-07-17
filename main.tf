# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
data "aws_availability_zones" "main" {}

locals {
  azs                 = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.main.names
  public_subnet_cidrs = var.public_subnet_cidrs == null ? [for i, _ in local.azs : cidrsubnet(var.cidr_block, 4, i)] : var.public_subnet_cidrs
  nat_gateway_count   = var.create_nat_gateways ? min(length(local.azs), length(local.public_subnet_cidrs), length(var.private_subnet_cidrs)) : 0
}

resource "aws_vpc" "main" {
  cidr_block                       = var.cidr_block
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = var.enable_dns_hostnames
  assign_generated_ipv6_cidr_block = true

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-vpc"
    },
  )
}

resource "aws_internet_gateway" "public" {
  count      = length(local.public_subnet_cidrs) > 0 ? 1 : 0
  depends_on = [aws_vpc.main]
  vpc_id     = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-public-igw"
    },
  )
}

resource "aws_egress_only_internet_gateway" "outbound" {
  count      = length(local.public_subnet_cidrs) > 0 ? 1 : 0
  depends_on = [aws_vpc.main]
  vpc_id     = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  count      = length(local.public_subnet_cidrs) > 0 ? 1 : 0
  depends_on = [aws_vpc.main]
  vpc_id     = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-public-rt"
    },
  )
}

resource "aws_route" "public" {
  count = length(local.public_subnet_cidrs) > 0 ? 1 : 0
  depends_on = [
    aws_internet_gateway.public,
    aws_route_table.public,
  ]
  route_table_id         = aws_route_table.public[0].id
  gateway_id             = aws_internet_gateway.public[0].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "ipv6-public" {
  count = length(local.public_subnet_cidrs) > 0 ? 1 : 0
  depends_on = [
    aws_internet_gateway.public,
    aws_route_table.public,
  ]
  route_table_id              = aws_route_table.public[0].id
  gateway_id                  = aws_internet_gateway.public[0].id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_subnet" "public" {
  count                           = length(local.public_subnet_cidrs)
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = local.public_subnet_cidrs[count.index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)
  availability_zone               = element(local.azs, count.index)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-public-subnet-${count.index + 1}"
      "type" = "public"
    },
  )
}

resource "aws_route_table_association" "public" {
  count          = length(local.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_eip" "private" {
  count = local.nat_gateway_count
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
  depends_on = [aws_vpc.main]
  count      = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id

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
  count                  = local.nat_gateway_count > 0 ? length(var.private_subnet_cidrs) : 0
  route_table_id         = aws_route_table.private[count.index].id
  nat_gateway_id         = element(aws_nat_gateway.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "ipv6-private" {
  depends_on = [
    aws_egress_only_internet_gateway.outbound,
    aws_route_table.private,
  ]
  count                       = length(local.public_subnet_cidrs) > 0 ? length(var.private_subnet_cidrs) : 0
  route_table_id              = aws_route_table.private[count.index].id
  egress_only_gateway_id      = aws_egress_only_internet_gateway.outbound[0].id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_subnet" "private" {
  count                           = length(var.private_subnet_cidrs)
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = var.private_subnet_cidrs[count.index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + length(local.public_subnet_cidrs))
  availability_zone               = element(local.azs, count.index)
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = true

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-private-subnet-${count.index + 1}"
      "type" = "private"
    },
  )
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


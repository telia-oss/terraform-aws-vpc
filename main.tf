# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
data "aws_availability_zones" "main" {}

data "aws_region" "current" {}

locals {
  azs               = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.main.names
  nat_gateway_count = var.create_nat_gateways ? min(length(local.azs), length(var.public_subnet_cidrs), length(var.private_subnet_cidrs)) : 0

  internet_gateway_count              = (var.create_internet_gateway && length(var.public_subnet_cidrs) > 0) ? 1 : 0
  egress_only_internet_gateway_count  = (var.create_egress_only_internet_gateway && length(var.private_subnet_cidrs) > 0) ? 1 : 0
  public_route_count                  = var.create_individual_public_subnet_route_tables ? length(var.public_subnet_cidrs) : local.internet_gateway_count
  create_public_subnet_default_routes = var.create_public_subnet_default_routes ? local.public_route_count : 0
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
  count      = local.internet_gateway_count
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
  count      = local.egress_only_internet_gateway_count
  depends_on = [aws_vpc.main]
  vpc_id     = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  count      = local.public_route_count
  depends_on = [aws_vpc.main]
  vpc_id     = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      "Name" = var.create_individual_public_subnet_route_tables ? "${var.name_prefix}-public-rt-${count.index + 1}" : "${var.name_prefix}-public-rt"
    },
  )
}

resource "aws_route" "public" {
  count = local.create_public_subnet_default_routes
  depends_on = [
    aws_internet_gateway.public,
    aws_route_table.public,
  ]
  route_table_id         = aws_route_table.public[count.index].id
  gateway_id             = aws_internet_gateway.public[0].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "ipv6-public" {
  count = local.create_public_subnet_default_routes
  depends_on = [
    aws_internet_gateway.public,
    aws_route_table.public,
  ]
  route_table_id              = aws_route_table.public[count.index].id
  gateway_id                  = aws_internet_gateway.public[0].id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_subnet" "public" {
  count                           = length(var.public_subnet_cidrs)
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = var.public_subnet_cidrs[count.index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, var.ipv6_public_subnet_netnum_offset + count.index)
  availability_zone               = element(local.azs, count.index)
  map_public_ip_on_launch         = var.map_public_ip_on_launch
  assign_ipv6_address_on_creation = true

  tags = merge(
    var.tags,
    var.public_subnet_tags,
    {
      "Name" = "${var.name_prefix}-public-subnet-${count.index + 1}"
      "Tier" = "Public"
    },
  )
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = var.create_individual_public_subnet_route_tables ? aws_route_table.public[count.index].id : aws_route_table.public[0].id
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
  count                       = length(var.private_subnet_cidrs) > 0 && local.egress_only_internet_gateway_count > 0 ? length(var.private_subnet_cidrs) : 0
  route_table_id              = aws_route_table.private[count.index].id
  egress_only_gateway_id      = aws_egress_only_internet_gateway.outbound[0].id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_subnet" "private" {
  count                           = length(var.private_subnet_cidrs)
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = var.private_subnet_cidrs[count.index]
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + (var.ipv6_private_subnet_netnum_offset == -1 ? length(var.public_subnet_cidrs) : var.ipv6_private_subnet_netnum_offset))
  availability_zone               = element(local.azs, count.index)
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = true

  tags = merge(
    var.tags,
    var.private_subnet_tags,
    {
      "Name" = "${var.name_prefix}-private-subnet-${count.index + 1}"
      "Tier" = "Private"
    },
  )
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_vpc_endpoint" "s3" {
  count           = var.enable_vpc_endpoints ? 1 : 0
  service_name    = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_id          = aws_vpc.main.id
  route_table_ids = compact(concat(aws_route_table.private.*.id, aws_route_table.public.*.id))
  policy          = var.s3_endpoint_policy
  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-s3"
    },
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  count           = var.enable_vpc_endpoints ? 1 : 0
  service_name    = "com.amazonaws.${data.aws_region.current.region}.dynamodb"
  vpc_id          = aws_vpc.main.id
  route_table_ids = compact(concat(aws_route_table.private.*.id, aws_route_table.public.*.id))
  policy          = var.dynamodb_endpoint_policy
  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-dynamodb"
    },
  )
}

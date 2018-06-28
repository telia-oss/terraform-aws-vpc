# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
data "aws_availability_zones" "main" {}

locals {
  az_count          = "${length(data.aws_availability_zones.main.names)}"
  private_count     = "${min(length(data.aws_availability_zones.main.names), var.private_subnet_count)}"
  nat_gateway_count = "${var.create_nat_gateways == "true"? min(length(data.aws_availability_zones.main.names),var.private_subnet_count) : 0 }"
}

# NOTE: depends_on is added for the vpc because terraform sometimes
# fails to destroy VPC's where internet gateway is attached. If this happens,
# we can manually detach it in the console and run terraform destroy again.
resource "aws_vpc" "main" {
  cidr_block                       = "${var.cidr_block}"
  instance_tenancy                 = "default"
  enable_dns_support               = "true"
  enable_dns_hostnames             = "${var.enable_dns_hostnames}"
  assign_generated_ipv6_cidr_block = "${var.assign_generated_ipv6_cidr_block}"

  tags = "${merge(var.tags, map("Name", "${var.name_prefix}-vpc"))}"
}

resource "aws_internet_gateway" "public" {
  depends_on = ["aws_vpc.main"]
  vpc_id     = "${aws_vpc.main.id}"

  tags = "${merge(var.tags, map("Name", "${var.name_prefix}-public-igw"))}"
}

resource "aws_egress_only_internet_gateway" "outbound" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public" {
  depends_on = ["aws_vpc.main"]
  vpc_id     = "${aws_vpc.main.id}"

  tags = "${merge(var.tags, map("Name", "${var.name_prefix}-public-rt"))}"
}

resource "aws_route" "public" {
  depends_on             = ["aws_internet_gateway.public", "aws_route_table.public"]
  route_table_id         = "${aws_route_table.public.id}"
  gateway_id             = "${aws_internet_gateway.public.id}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "ipv6-public" {
  depends_on                  = ["aws_internet_gateway.public", "aws_route_table.public"]
  route_table_id              = "${aws_route_table.public.id}"
  gateway_id                  = "${aws_internet_gateway.public.id}"
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_subnet" "public" {
  count                           = "${local.az_count}"
  vpc_id                          = "${aws_vpc.main.id}"
  cidr_block                      = "${cidrsubnet(var.cidr_block, 4, count.index)}"
  ipv6_cidr_block                 = "${var.assign_generated_ipv6_cidr_block == "true" ? "$(aws_vpc.main.ipv6_cidr_block, 8, count.index)" : ""}"
  availability_zone               = "${element(data.aws_availability_zones.main.names, count.index)}"
  map_public_ip_on_launch         = "true"
  assign_ipv6_address_on_creation = "true"

  tags = "${merge(var.tags, map("Name", "${var.name_prefix}-public-subnet-${count.index + 1}"))}"
}

resource "aws_route_table_association" "public" {
  count          = "${local.az_count}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_eip" "private" {
  count = "${local.nat_gateway_count}"
}

resource "aws_nat_gateway" "private" {
  depends_on    = ["aws_internet_gateway.public", "aws_eip.private"]
  count         = "${local.nat_gateway_count}"
  allocation_id = "${element(aws_eip.private.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"

  tags = "${merge(var.tags, map("Name", "${var.name_prefix}-nat-gateway-${count.index + 1}"))}"
}

resource "aws_route_table" "private" {
  depends_on = ["aws_vpc.main"]
  count      = "${local.private_count}"
  vpc_id     = "${aws_vpc.main.id}"

  tags = "${merge(var.tags, map("Name", "${var.name_prefix}-private-rt-${count.index + 1}"))}"
}

resource "aws_route" "private" {
  depends_on             = ["aws_nat_gateway.private", "aws_route_table.private"]
  count                  = "${local.nat_gateway_count}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  nat_gateway_id         = "${element(aws_nat_gateway.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "ipv6-private" {
  depends_on                  = ["aws_egress_only_internet_gateway.outbound", "aws_route_table.private"]
  count                       = "${local.private_count}"
  route_table_id              = "${element(aws_route_table.private.*.id, count.index)}"
  egress_only_gateway_id      = "${aws_egress_only_internet_gateway.outbound.id}"
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_subnet" "private" {
  count                           = "${local.private_count}"
  vpc_id                          = "${aws_vpc.main.id}"
  cidr_block                      = "${cidrsubnet(var.cidr_block, 4, local.az_count + count.index)}"
  ipv6_cidr_block                 = "${var.assign_generated_ipv6_cidr_block == "true" ? "$(aws_vpc.main.ipv6_cidr_block, 8, count.index)" : ""}"
  availability_zone               = "${element(data.aws_availability_zones.main.names, count.index)}"
  map_public_ip_on_launch         = "false"
  assign_ipv6_address_on_creation = "true"

  tags = "${merge(var.tags, map("Name", "${var.name_prefix}-private-subnet-${count.index + 1}"))}"
}

resource "aws_route_table_association" "private" {
  count          = "${local.private_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

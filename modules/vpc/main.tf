#--------------------------------------------------------------
# Recipe
# 
# + get res vpc
# + get res vpc internet gateway
# + get res vpc routing table
# + get res vpc internet gateway route
# + get res vpc internet gateway vpn route
# + get res vpc nat gateway route
# + get res vpc private route
# + get res vpc vpn route
# + get res vpc subnet private
# + get res vpc subnet database
# + get res vpc subnet vpn
# + get res vpc subnet group database
# + get res vpc subnet elasticache
# + get res vpc subnet public
# + get res vpc nat ip
# + get res vpc nat gateway
#--------------------------------------------------------------

# + get res vpc
resource "aws_vpc" "mod" {
  cidr_block           = "${var.cidr}"
  instance_tenancy     = "${var.instance_tenancy}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support   = "${var.enable_dns_support}"
  tags                 = "${merge(var._tags, var.tags, map("Name", format("%s", var.name)))}"
}

# + get res vpc internet gateway
resource "aws_internet_gateway" "mod" {
  vpc_id = "${aws_vpc.mod.id}"
  tags   = "${merge(var._tags, var.tags, map("Name", format("%s-igw", var.name)))}"
}

# + get res vpc routing table
resource "aws_route_table" "public" {
  vpc_id           = "${aws_vpc.mod.id}"
  propagating_vgws = ["${var.public_propagating_vgws}"]
  tags             = "${merge(var._tags, var.tags, map("Name", format("%s-public", var.name)))}"
}

# + get res vpc internet gateway route
resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.mod.id}"
}

# + get res vpc vpn route
resource "aws_route" "vpn_internet_gateway" {
  route_table_id         = "${aws_route_table.vpn.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.mod.id}"
}

# + get res vpc nat gateway
resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.natgw.*.id, count.index)}"
  count                  = "${var.enable_nat_gateway ? length(var.azs) : 0}"
}

# + get res vpc private route
resource "aws_route_table" "private" {
  vpc_id           = "${aws_vpc.mod.id}"
  propagating_vgws = ["${var.private_propagating_vgws}"]
  count            = "${length(var.azs)}"
  tags             = "${merge(var._tags, var.tags, map("Name", format("%s-private-%s", var.name, element(var.azs, count.index))))}"
}

# + get res vpc vpn route
resource "aws_route_table" "vpn" {
  vpc_id            = "${aws_vpc.mod.id}"
  propagating_vgws = ["${var.vpn_propagating_vgws}"]
  tags              = "${merge(var._tags, var.tags, map("Name", format("%s-vpn", var.name)))}"
}

# + get res vpc subnet private
resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "${var.private_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.private_subnets)}"
  tags              = "${merge(var._tags, var.tags, var.private_subnet_tags, map("Name", format("%s-private-%s", var.name, element(var.azs, count.index))))}"
}

# + get res vpc subnet database
resource "aws_subnet" "database" {
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "${var.database_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.database_subnets)}"
  tags              = "${merge(var._tags, var.tags, var.database_subnet_tags, map("Name", format("%s-database-%s", var.name, element(var.azs, count.index))))}"
}

# + get res vpc subnet vpn
resource "aws_subnet" "vpn" {
  vpc_id              = "${aws_vpc.mod.id}"
  cidr_block          = "${var.vpn_subnet}"
  tags                = "${merge(var._tags, var.tags, var.vpn_subnet_tags, map("Name", format("%s-vpn-%s", var.name, element(var.azs, 0))))}"
}

# + get res vpc subnet group database
resource "aws_db_subnet_group" "database" {
  name        = "${var.name}-rds"
  description = "Database subnet groups for ${var.name}"
  subnet_ids  = ["${aws_subnet.database.*.id}"]
  tags        = "${merge(var._tags, var.tags, map("Name", format("%s-database", var.name)))}"
  count       = "${length(var.database_subnets) > 0 ? 1 : 0}"
}

# + get res vpc subnet group database
resource "aws_subnet" "elasticache" {
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "${var.elasticache_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.elasticache_subnets)}"
  tags              = "${merge(var._tags, var.tags, var.elasticache_subnet_tags, map("Name", format("%s-elasticache-%s", var.name, element(var.azs, count.index))))}"
}

# + get res vpc subnet elasticache
resource "aws_elasticache_subnet_group" "elasticache" {
  name        = "${var.name}-elasticache"
  description = "Elasticache subnet groups for ${var.name}"
  subnet_ids  = ["${aws_subnet.elasticache.*.id}"]
  count       = "${length(var.elasticache_subnets) > 0 ? 1 : 0}"
}

# + get res vpc subnet public
resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "${var.public_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.public_subnets)}"
  tags              = "${merge(var._tags, var.tags, var.public_subnet_tags, map("Name", format("%s-public-%s", var.name, element(var.azs, count.index))))}"

  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"
}

# + get res vpc nat ip
resource "aws_eip" "nateip" {
  vpc   = true
  count = "${var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0}"
}

# + get res vpc nat gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = "${element(aws_eip.nateip.*.id, (var.single_nat_gateway ? 0 : count.index))}"
  subnet_id     = "${element(aws_subnet.public.*.id, (var.single_nat_gateway ? 0 : count.index))}"
  count         = "${var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0}"

  depends_on = ["aws_internet_gateway.mod"]
}

data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
}

resource "aws_vpc_endpoint" "ep" {
  vpc_id       = "${aws_vpc.mod.id}"
  service_name = "${data.aws_vpc_endpoint_service.s3.service_name}"
  count        = "${var.enable_s3_endpoint}"
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = "${var.enable_s3_endpoint ? length(var.private_subnets) : 0}"
  vpc_endpoint_id = "${aws_vpc_endpoint.ep.id}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  count           = "${var.enable_s3_endpoint ? length(var.public_subnets) : 0}"
  vpc_endpoint_id = "${aws_vpc_endpoint.ep.id}"
  route_table_id  = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_route_table_association" "database" {
  count          = "${length(var.database_subnets)}"
  subnet_id      = "${element(aws_subnet.database.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_route_table_association" "elasticache" {
  count          = "${length(var.elasticache_subnets)}"
  subnet_id      = "${element(aws_subnet.elasticache.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "vpn" {
  subnet_id      = "${aws_subnet.vpn.id}"
  route_table_id = "${aws_route_table.vpn.id}"
}

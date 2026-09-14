# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}


# Public subnets
resource "aws_subnet" "public_subnets" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "${var.name_prefix}-public-${each.value.index}"
    Tier                                            = "public"
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

# Private subnets
resource "aws_subnet" "private_subents" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name                                            = "${var.name_prefix}-private-${each.value.index}"
    Tier                                            = "private"
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}
# Internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# NAT gateway
resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_azs)

  allocation_id = aws_eip.nat[each.value].id
  subnet_id     = aws_subnet.public_subnets[each.value].id

  tags = {
    Name = "${var.name_prefix}-nat-${each.value}"
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

# Elastic IPs for NAT gateways
resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)

  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-nat-eip-${each.value}"
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

# Public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}
# Public route to the internet
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = var.internet_route_cidr
  gateway_id             = aws_internet_gateway.internet_gateway.id
}
# Public route-table associations
resource "aws_route_table_association" "public_route_table_association" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  for_each = toset(local.nat_azs)

  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.name_prefix}-private-rt-${each.value}"
  }
}

# Private routes to NAT gateways
resource "aws_route" "private_nat" {
  for_each = aws_route_table.private_route_table

  route_table_id         = each.value.id
  destination_cidr_block = var.internet_route_cidr
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

# Private route-table associations
resource "aws_route_table_association" "private_route_table_association" {
  for_each = var.enable_nat_gateway ? aws_subnet.private_subents : {}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table[var.enable_nat_per_az ? each.key : local.azs[0]].id
}

# Private route-table associations without NAT gateways
resource "aws_route_table_association" "private_no_nat" {
  for_each = var.enable_nat_gateway ? {} : aws_subnet.private_subents

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

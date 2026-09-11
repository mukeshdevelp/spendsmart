data "aws_availability_zones" "available" {
  state = "available"
}

# locals define
locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)

  # for two public subnets
  public_subnets = {
    for idx, az in local.azs : az => {
      az    = az
      cidr  = var.public_subnet_cidrs[idx]
      index = idx + 1
    }
  }
  # for two private subnets
  private_subnets = {
    for idx, az in local.azs : az => {
      az    = az
      cidr  = var.private_subnet_cidrs[idx]
      index = idx + 1
    }
  }

  nat_azs = var.enable_nat_gateway ? (var.enable_nat_per_az ? local.azs : [local.azs[0]]) : []

  nacl_ingress_from_public_tcp = {
    for item in flatten([
      for cidr_idx, cidr in var.public_subnet_cidrs : [
        for port_idx, port in var.nodes_nacl_ingress_from_public_tcp_ports : {
          key         = "${cidr}:${port}"
          rule_number = 100 + cidr_idx * max(length(var.nodes_nacl_ingress_from_public_tcp_ports), 1) + port_idx
          cidr_block  = cidr
          from_port   = port
          to_port     = port
        }
      ]
    ]) : item.key => item
  }

  nacl_egress_internet_tcp = {
    for idx, port in var.nodes_nacl_egress_internet_tcp_ports : "tcp-${port}" => {
      rule_number = 100 + idx
      from_port   = port
      to_port     = port
    }
  }

  nacl_egress_internet_udp = {
    for idx, port in var.nodes_nacl_egress_internet_udp_ports : "udp-${port}" => {
      rule_number = 150 + idx
      from_port   = port
      to_port     = port
    }
  }

  nacl_ephemeral = {
    for idx, proto in var.nodes_nacl_ephemeral_protocols : proto => {
      rule_number = 300 + idx
      protocol    = proto
      from_port   = var.nodes_nacl_ephemeral_from_port
      to_port     = var.nodes_nacl_ephemeral_to_port
    }
  }
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

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

resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)

  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-nat-eip-${each.value}"
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_azs)

  allocation_id = aws_eip.nat[each.value].id
  subnet_id     = aws_subnet.public_subnets[each.value].id

  tags = {
    Name = "${var.name_prefix}-nat-${each.value}"
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

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

resource "aws_route" "private_nat" {
  for_each = aws_route_table.private_route_table

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private_route_table_association" {
  for_each = var.enable_nat_gateway ? aws_subnet.private_subents : {}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table[var.enable_nat_per_az ? each.key : local.azs[0]].id
}

resource "aws_route_table_association" "private_no_nat" {
  for_each = var.enable_nat_gateway ? {} : aws_subnet.private_subents

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_network_acl" "nodes" {
  count = var.enable_nodes_nacl ? 1 : 0

  vpc_id     = aws_vpc.main_vpc.id
  subnet_ids = [for s in aws_subnet.private_subents : s.id]

  tags = {
    Name = "${var.name_prefix}-nodes-nacl"
  }
}

resource "aws_network_acl_rule" "nodes_ingress_from_public_tcp" {
  for_each = var.enable_nodes_nacl ? local.nacl_ingress_from_public_tcp : {}

  network_acl_id = aws_network_acl.nodes[0].id
  rule_number    = each.value.rule_number
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

resource "aws_network_acl_rule" "nodes_ingress_vpc" {
  count = var.enable_nodes_nacl && var.nodes_nacl_ingress_allow_vpc ? 1 : 0

  network_acl_id = aws_network_acl.nodes[0].id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "nodes_ingress_ephemeral" {
  for_each = var.enable_nodes_nacl ? local.nacl_ephemeral : {}

  network_acl_id = aws_network_acl.nodes[0].id
  rule_number    = each.value.rule_number
  egress         = false
  protocol       = each.value.protocol
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

resource "aws_network_acl_rule" "nodes_egress_internet_tcp" {
  for_each = var.enable_nodes_nacl ? local.nacl_egress_internet_tcp : {}

  network_acl_id = aws_network_acl.nodes[0].id
  rule_number    = each.value.rule_number
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

resource "aws_network_acl_rule" "nodes_egress_internet_udp" {
  for_each = var.enable_nodes_nacl ? local.nacl_egress_internet_udp : {}

  network_acl_id = aws_network_acl.nodes[0].id
  rule_number    = each.value.rule_number
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

resource "aws_network_acl_rule" "nodes_egress_vpc" {
  count = var.enable_nodes_nacl && var.nodes_nacl_egress_allow_vpc ? 1 : 0

  network_acl_id = aws_network_acl.nodes[0].id
  rule_number    = 200
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "nodes_egress_ephemeral" {
  for_each = var.enable_nodes_nacl ? local.nacl_ephemeral : {}

  network_acl_id = aws_network_acl.nodes[0].id
  rule_number    = each.value.rule_number
  egress         = true
  protocol       = each.value.protocol
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

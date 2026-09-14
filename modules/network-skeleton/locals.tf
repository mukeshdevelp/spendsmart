data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets = {
    for idx, az in local.azs : az => {
      az    = az
      cidr  = var.public_subnet_cidrs[idx]
      index = idx + 1
    }
  }

  private_subnets = {
    for idx, az in local.azs : az => {
      az    = az
      cidr  = var.private_subnet_cidrs[idx]
      index = idx + 1
    }
  }

  nat_azs = var.enable_nat_gateway ? (var.enable_nat_per_az ? local.azs : [local.azs[0]]) : []
}

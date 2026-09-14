variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Two availability zones. Leave empty to use the first two AZs in the region."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ."
  type        = list(string)
}

variable "eks_cluster_name" {
  description = "EKS cluster name for subnet tags."
  type        = string
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) so private subnets can reach the internet."
  type        = bool
}

variable "enable_nat_per_az" {
  description = "If true, create one NAT gateway in each public subnet."
  type        = bool
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames on the VPC."
  type        = bool
}

variable "enable_dns_support" {
  description = "Enable DNS support on the VPC."
  type        = bool
}

variable "internet_route_cidr" {
  description = "Destination CIDR for default routes to the internet (public IGW and private NAT)."
  type        = string
  default     = "0.0.0.0/0"
}

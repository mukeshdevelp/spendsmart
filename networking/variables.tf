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

variable "enable_nodes_nacl" {
  description = "Create a custom Network ACL on private/node subnets."
  type        = bool
}

variable "nodes_nacl_ingress_from_public_tcp_ports" {
  description = "TCP ports allowed inbound to node subnets from each public subnet CIDR."
  type        = list(number)
}

variable "nodes_nacl_ingress_allow_vpc" {
  description = "Allow all inbound traffic from the VPC CIDR into node subnets."
  type        = bool
}

variable "nodes_nacl_ephemeral_from_port" {
  description = "First port in the ephemeral range allowed as return traffic."
  type        = number
}

variable "nodes_nacl_ephemeral_to_port" {
  description = "Last port in the ephemeral range allowed as return traffic."
  type        = number
}

variable "nodes_nacl_ephemeral_protocols" {
  description = "Protocols for ephemeral NACL rules."
  type        = list(string)
}

variable "nodes_nacl_egress_internet_tcp_ports" {
  description = "TCP ports allowed outbound from node subnets to 0.0.0.0/0."
  type        = list(number)
}

variable "nodes_nacl_egress_internet_udp_ports" {
  description = "UDP ports allowed outbound from node subnets to 0.0.0.0/0."
  type        = list(number)
}

variable "nodes_nacl_egress_allow_vpc" {
  description = "Allow all outbound traffic from node subnets to the VPC CIDR."
  type        = bool
}

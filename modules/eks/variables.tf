variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the EKS cluster."
  type        = list(string)
}

variable "private_subnet_map" {
  description = "Private subnet details keyed by availability zone."
  type = map(object({
    id    = string
    az    = string
    index = number
  }))
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB."
  type        = list(string)
}

variable "eks_cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
}

variable "eks_endpoint_private_access" {
  description = "Enable the private EKS API endpoint."
  type        = bool
}

variable "eks_endpoint_public_access" {
  description = "Enable the public EKS API endpoint."
  type        = bool
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint."
  type        = list(string)
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS managed node groups."
  type        = list(string)
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in each node group."
  type        = number
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in each node group."
  type        = number
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in each node group."
  type        = number
}

variable "eks_node_disk_size" {
  description = "Node root disk size in GiB."
  type        = number
}

variable "eks_node_capacity_type" {
  description = "Capacity type for node groups."
  type        = string
}

variable "eks_node_ami_type" {
  description = "AMI type for managed node groups."
  type        = string
}

variable "ec2_key_name" {
  description = "EC2 key pair name for node launch template."
  type        = string
  default     = null
}

variable "bastion_enabled" {
  description = "Allow SSH to nodes from bastion security group."
  type        = bool
}

variable "bastion_security_group_id" {
  description = "Bastion security group ID."
  type        = string
  default     = null
}

variable "clickhouse_enabled" {
  description = "Create ClickHouse ingress rules from EKS nodes."
  type        = bool
  default     = false
}

variable "clickhouse_security_group_id" {
  description = "ClickHouse security group ID."
  type        = string
  default     = null
}

variable "clickhouse_http_port" {
  description = "ClickHouse HTTP port."
  type        = number
  default     = 8123
}

variable "clickhouse_native_port" {
  description = "ClickHouse native TCP port."
  type        = number
  default     = 9000
}

variable "alb_enabled" {
  description = "Create an Application Load Balancer."
  type        = bool
}

variable "alb_internal" {
  description = "Create an internal ALB."
  type        = bool
}

variable "alb_listener_port" {
  description = "ALB listener port."
  type        = number
}

variable "alb_listener_protocol" {
  description = "ALB listener protocol."
  type        = string
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener."
  type        = string
  default     = ""
}

variable "alb_target_port" {
  description = "Target group port."
  type        = number
}

variable "alb_health_check_path" {
  description = "HTTP health-check path."
  type        = string
}

variable "alb_health_check_matcher" {
  description = "HTTP status codes treated as healthy."
  type        = string
}

variable "create_route53_zone" {
  description = "Create a Route 53 hosted zone."
  type        = bool
}

variable "route53_zone_id" {
  description = "Existing Route 53 hosted zone ID."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "DNS zone name."
  type        = string
}

variable "app_hostname" {
  description = "Record name for the ALB alias."
  type        = string
}

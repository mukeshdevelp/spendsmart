variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "project_name" {
  description = "Name prefix used on resources."
  type        = string
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all supported resources via the provider default_tags block."
  type        = map(string)
  default     = {}
}

variable "availability_zones" {
  description = "Two availability zones. Leave empty to use the first two AZs in the region."
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ (order matches availability_zones)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ (order matches availability_zones)."
  type        = list(string)
}

variable "enable_nodes_nacl" {
  description = "Create a custom Network ACL and associate it with the private/node subnets."
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
  description = "Protocols for ephemeral NACL rules, for example tcp and udp."
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

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) so private subnets can reach the internet."
  type        = bool
}

variable "enable_nat_per_az" {
  description = "If true, create one NAT gateway in each public subnet. If false, use a single NAT in the first public subnet (matches the diagram)."
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

variable "bastion_enabled" {
  description = "Create the public-subnet bastion host."
  type        = bool
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host."
  type        = string
}

variable "create_ssh_key" {
  description = "Create an EC2 key pair in AWS (CreateKeyPair API) and store the private key PEM in Secrets Manager."
  type        = bool
}

variable "ssh_key_name" {
  description = "EC2 key pair name. Leave empty to use project-environment-ssh-key."
  type        = string
  default     = ""
}

variable "ssh_private_key_secret_name" {
  description = "Secrets Manager secret name for the SSH private key PEM. Leave empty to use project-environment-ssh-private-key."
  type        = string
  default     = ""
}

variable "ssh_key_secret_recovery_window_days" {
  description = "Days to retain the secret after delete (0 = immediate delete, 7-30 typical for production)."
  type        = number
  default     = 7
}

variable "bastion_key_name" {
  description = "Existing EC2 key pair when create_ssh_key is false. Leave empty for no SSH key on instances."
  type        = string
  default     = ""
}

variable "bastion_allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to the bastion."
  type        = list(string)
}

variable "bastion_associate_eip" {
  description = "Allocate and associate an Elastic IP with the bastion."
  type        = bool
}

variable "clickhouse_enabled" {
  description = "Create a self-managed ClickHouse EC2 instance in a private subnet."
  type        = bool
}

variable "clickhouse_instance_type" {
  description = "EC2 instance type for ClickHouse."
  type        = string
}

variable "clickhouse_root_volume_size" {
  description = "Root EBS volume size in GiB for ClickHouse."
  type        = number
}

variable "clickhouse_data_volume_size" {
  description = "Additional data EBS volume size in GiB for ClickHouse."
  type        = number
}

variable "clickhouse_http_port" {
  description = "ClickHouse HTTP port."
  type        = number
}

variable "clickhouse_native_port" {
  description = "ClickHouse native TCP port."
  type        = number
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

variable "eks_enabled_cluster_log_types" {
  description = "EKS control-plane log types to send to CloudWatch."
  type        = list(string)
}

variable "eks_node_instance_types" {
  description = "Instance types for both EKS managed node groups."
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
  description = "Capacity type for node groups (ON_DEMAND or SPOT)."
  type        = string
}

variable "eks_node_ami_type" {
  description = "AMI type for managed node groups."
  type        = string
}

variable "alb_enabled" {
  description = "Create an internet-facing Application Load Balancer in the public subnets."
  type        = bool
}

variable "alb_internal" {
  description = "If true, create an internal ALB instead of an internet-facing ALB."
  type        = bool
}

variable "alb_listener_port" {
  description = "ALB listener port."
  type        = number
}

variable "alb_listener_protocol" {
  description = "ALB listener protocol (HTTP or HTTPS)."
  type        = string
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN required when alb_listener_protocol is HTTPS."
  type        = string
  default     = ""
}

variable "alb_target_port" {
  description = "Target group port (typically a NodePort or pod port exposed on EKS nodes)."
  type        = number
}

variable "alb_health_check_path" {
  description = "HTTP health-check path for the ALB target group."
  type        = string
}

variable "alb_health_check_matcher" {
  description = "HTTP status codes treated as healthy."
  type        = string
}

variable "create_route53_zone" {
  description = "Create a public Route 53 hosted zone for domain_name."
  type        = bool
}

variable "route53_zone_id" {
  description = "Existing Route 53 hosted zone ID. Used when create_route53_zone is false."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "DNS zone name, for example spendsmart.example.com."
  type        = string
}

variable "app_hostname" {
  description = "Record name for the ALB alias, for example app.spendsmart.example.com. Use the zone apex by setting this equal to domain_name."
  type        = string
}

variable "data_bucket_name" {
  description = "Optional explicit S3 data-lake bucket name. Leave empty to derive from project and environment."
  type        = string
  default     = ""
}

variable "athena_results_bucket_name" {
  description = "Optional explicit Athena results bucket name. Leave empty to derive from project and environment."
  type        = string
  default     = ""
}

variable "glue_database_name" {
  description = "Glue Data Catalog database name."
  type        = string
}

variable "athena_workgroup_name" {
  description = "Athena workgroup name."
  type        = string
}

variable "athena_bytes_scanned_cutoff" {
  description = "Athena per-query bytes-scanned cutoff. Set 0 to disable."
  type        = number
}

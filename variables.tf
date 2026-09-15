variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "state_file_key" {
  description = "S3 key for the Terraform state file."
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

variable "ec2_key_name" {
  description = "Name of an existing EC2 key pair in this AWS account and region. It is validated and attached to the bastion and EKS worker nodes."
  type        = string
}

variable "internet_route_cidr" {
  description = "Destination CIDR for default VPC routes to the internet (IGW and NAT)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "bastion_ssh_port" {
  description = "TCP port for SSH ingress to the bastion security group."
  type        = number
  default     = 22
}

variable "bastion_allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to the bastion."
  type        = list(string)
}

variable "bastion_associate_eip" {
  description = "Allocate and associate an Elastic IP with the bastion."
  type        = bool
}

variable "bastion_egress_cidrs" {
  description = "CIDR blocks allowed for bastion egress."
  type        = string
}

variable "bastion_root_volume_size" {
  description = "Root EBS volume size in GiB for the bastion."
  type        = number
}

variable "bastion_root_volume_type" {
  description = "Root EBS volume type for the bastion."
  type        = string
}

variable "bastion_ami_ssm_parameter" {
  description = "SSM parameter path for the bastion AMI."
  type        = string
}

variable "ec2_ssm_policy_arn" {
  description = "IAM policy ARN for SSM on the bastion."
  type        = string
}

variable "nodes_ssh_port" {
  description = "SSH port on EKS nodes."
  type        = number
}

variable "nodes_egress_cidrs" {
  description = "CIDR blocks allowed for EKS node egress."
  type        = list(string)
}

variable "sg_protocol_tcp" {
  description = "TCP protocol value for security group rules."
  type        = string
  default     = "tcp"
}

variable "sg_protocol_all" {
  description = "All-traffic protocol value for security group rules."
  type        = string
  default     = "-1"
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

variable "eks_authentication_mode" {
  description = "EKS cluster authentication mode."
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "eks_bootstrap_cluster_creator_admin_permissions" {
  description = "Grant cluster-creator admin permissions on the EKS cluster."
  type        = bool
  default     = true
}

variable "eks_assume_role_action" {
  description = "STS action for EKS IAM assume-role policies."
  type        = string
  default     = "sts:AssumeRole"
}

variable "eks_cluster_assume_role_principal_type" {
  description = "Principal type for the EKS cluster IAM role."
  type        = string
  default     = "Service"
}

variable "eks_cluster_assume_role_service" {
  description = "Service principal for the EKS cluster IAM role."
  type        = string
  default     = "eks.amazonaws.com"
}

variable "eks_node_assume_role_principal_type" {
  description = "Principal type for the EKS node IAM role."
  type        = string
  default     = "Service"
}

variable "eks_node_assume_role_service" {
  description = "Service principal for the EKS node IAM role."
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "eks_cluster_role_name_suffix" {
  description = "Suffix appended to name_prefix for the EKS cluster IAM role."
  type        = string
  default     = "-eks-cluster"
}

variable "eks_nodes_role_name_suffix" {
  description = "Suffix appended to name_prefix for the EKS node IAM role."
  type        = string
  default     = "-eks-nodes"
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

variable "eks_node_disk_type" {
  description = "Node root disk type."
  type        = string
}

variable "eks_node_device_name" {
  description = "Block device name for the node root volume."
  type        = string
}

variable "eks_node_volume_encrypted" {
  description = "Encrypt EKS node root EBS volumes."
  type        = bool
  default     = true
}

variable "eks_node_volume_delete_on_termination" {
  description = "Delete EKS node root EBS volumes on instance termination."
  type        = bool
  default     = true
}

variable "eks_node_metadata_http_endpoint" {
  description = "IMDSv2 HTTP endpoint setting for EKS nodes."
  type        = string
  default     = "enabled"
}

variable "eks_node_metadata_http_tokens" {
  description = "IMDSv2 token requirement for EKS nodes."
  type        = string
  default     = "required"
}

variable "eks_node_metadata_http_put_response_hop_limit" {
  description = "IMDSv2 hop limit for EKS nodes."
  type        = number
  default     = 2
}

variable "eks_node_instance_tag_resource_type" {
  description = "Launch template tag specification resource type for EKS nodes."
  type        = string
  default     = "instance"
}

variable "eks_node_launch_template_name_suffix" {
  description = "Suffix appended to name_prefix for the node launch template name prefix."
  type        = string
  default     = "-ng-"
}

variable "eks_node_instance_name_suffix" {
  description = "Suffix appended to name_prefix for EKS node instance Name tags."
  type        = string
  default     = "-eks-node"
}

variable "eks_node_group_tag_name_suffix" {
  description = "Suffix appended to name_prefix for EKS node group Name tags."
  type        = string
  default     = "-node-group-"
}

variable "eks_nodes_security_group_description" {
  description = "Description for the EKS nodes security group."
  type        = string
  default     = "Additional security group for EKS worker nodes"
}

variable "eks_nodes_security_group_name_suffix" {
  description = "Suffix appended to name_prefix for the EKS nodes security group."
  type        = string
  default     = "-eks-nodes"
}

variable "eks_nodes_cluster_tag_key_prefix" {
  description = "Kubernetes cluster ownership tag key prefix for EKS nodes."
  type        = string
  default     = "kubernetes.io/cluster/"
}

variable "eks_nodes_cluster_tag_value" {
  description = "Kubernetes cluster ownership tag value for EKS nodes."
  type        = string
  default     = "owned"
}

variable "eks_nodes_self_ingress_description" {
  description = "Description for node-to-node security group ingress."
  type        = string
  default     = "Node to node"
}

variable "eks_nodes_alb_ingress_description" {
  description = "Description for ALB-to-node security group ingress."
  type        = string
  default     = "ALB to node target port"
}

variable "eks_nodes_ssh_ingress_description" {
  description = "Description for bastion-to-node SSH security group ingress."
  type        = string
  default     = "SSH from bastion"
}

variable "eks_nodes_egress_description" {
  description = "Description for EKS node egress security group rules."
  type        = string
  default     = "Node egress"
}

variable "eks_node_group_name_prefix" {
  description = "Prefix for managed node group names."
  type        = string
}

variable "eks_node_az_label_key" {
  description = "Kubernetes label key used to tag nodes with their AZ."
  type        = string
}

variable "eks_node_update_max_unavailable" {
  description = "Maximum unavailable nodes during a node group update."
  type        = number
}

variable "eks_addons" {
  description = "EKS add-on names to install after node groups are ready."
  type        = list(string)
}

variable "eks_cluster_policy_arn" {
  description = "IAM policy ARN attached to the EKS cluster role."
  type        = string
}

variable "eks_vpc_resource_controller_policy_arn" {
  description = "IAM policy ARN for the EKS VPC resource controller."
  type        = string
}

variable "eks_node_worker_policy_arn" {
  description = "IAM policy ARN for EKS worker nodes."
  type        = string
}

variable "eks_node_cni_policy_arn" {
  description = "IAM policy ARN for the EKS CNI plugin."
  type        = string
}

variable "eks_node_ecr_policy_arn" {
  description = "IAM policy ARN for ECR read access on nodes."
  type        = string
}

variable "eks_node_ssm_policy_arn" {
  description = "IAM policy ARN for SSM on EKS nodes."
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

variable "alb_allowed_ingress_cidr" {
  description = "CIDR blocks allowed to reach the ALB listener."
  type        = string
}

variable "alb_security_group_name_suffix" {
  description = "Suffix appended to name_prefix for the ALB security group and load balancer."
  type        = string
  default     = "-alb"
}

variable "alb_security_group_description" {
  description = "Description for the ALB security group."
  type        = string
  default     = "Application Load Balancer"
}

variable "alb_ingress_rule_description" {
  description = "Description for ALB listener ingress security group rules."
  type        = string
  default     = "ALB listener"
}

variable "alb_egress_to_nodes_description" {
  description = "Description for ALB-to-node egress security group rules."
  type        = string
  default     = "ALB to EKS nodes"
}

variable "alb_load_balancer_type" {
  description = "Load balancer type for the ALB."
  type        = string
  default     = "application"
}

variable "alb_listener_port" {
  description = "ALB listener port."
  type        = number
}

variable "alb_listener_protocol" {
  description = "ALB listener protocol (HTTP or HTTPS)."
  type        = string
}

variable "alb_listener_protocol_https" {
  description = "Protocol value that triggers HTTPS listener settings."
  type        = string
  default     = "HTTPS"
}

variable "alb_listener_action_type" {
  description = "Default action type for the ALB listener."
  type        = string
  default     = "forward"
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN required when alb_listener_protocol is HTTPS."
  type        = string
  default     = ""
}

variable "alb_ssl_policy" {
  description = "SSL policy for HTTPS listeners."
  type        = string
}

variable "alb_target_port" {
  description = "Target group port (typically a NodePort or pod port exposed on EKS nodes)."
  type        = number
}

variable "alb_target_group_name_suffix" {
  description = "Suffix appended to name_prefix for the ALB target group."
  type        = string
  default     = "-eks"
}

variable "alb_target_group_tag_name_suffix" {
  description = "Suffix appended to name_prefix for the ALB target group Name tag."
  type        = string
  default     = "-eks-tg"
}

variable "alb_target_group_protocol" {
  description = "Target group protocol."
  type        = string
  default     = "HTTP"
}

variable "alb_health_check_enabled" {
  description = "Enable ALB target group health checks."
  type        = bool
  default     = true
}

variable "alb_health_check_path" {
  description = "HTTP health-check path for the ALB target group."
  type        = string
}

variable "alb_health_check_matcher" {
  description = "HTTP status codes treated as healthy."
  type        = string
}

variable "alb_health_check_interval" {
  description = "Health check interval in seconds."
  type        = number
}

variable "alb_health_check_timeout" {
  description = "Health check timeout in seconds."
  type        = number
}

variable "alb_health_check_healthy_threshold" {
  description = "Consecutive successful health checks required."
  type        = number
}

variable "alb_health_check_unhealthy_threshold" {
  description = "Consecutive failed health checks required."
  type        = number
}

variable "bucket_name" {
  description = "Shared S3 bucket name. Leave empty to derive a name from project, environment, and AWS account ID."
  type        = string
  default     = ""
}

variable "data_prefix" {
  description = "S3 key prefix for Glue / data-lake objects."
  type        = string
  default     = "data"
}

variable "athena_results_prefix" {
  description = "S3 key prefix for Athena query results."
  type        = string
  default     = "athena-results"
}

variable "bucket_force_destroy" {
  description = "Allow Terraform to delete the bucket when empty. Keep false to retain the bucket on destroy."
  type        = bool
  default     = false
}

variable "bucket_versioning_enabled" {
  description = "Enable versioning on the shared S3 bucket."
  type        = bool
  default     = true
}

variable "bucket_sse_algorithm" {
  description = "Server-side encryption algorithm for the shared S3 bucket."
  type        = string
  default     = "AES256"
}

variable "bucket_key_enabled" {
  description = "Enable S3 bucket keys for server-side encryption."
  type        = bool
  default     = true
}

variable "bucket_block_public_acls" {
  description = "Block public ACLs on the shared S3 bucket."
  type        = bool
  default     = true
}

variable "bucket_block_public_policy" {
  description = "Block public bucket policies on the shared S3 bucket."
  type        = bool
  default     = true
}

variable "bucket_ignore_public_acls" {
  description = "Ignore public ACLs on the shared S3 bucket."
  type        = bool
  default     = true
}

variable "bucket_restrict_public_buckets" {
  description = "Restrict public bucket policies on the shared S3 bucket."
  type        = bool
  default     = true
}

variable "athena_lifecycle_rule_id" {
  description = "Lifecycle rule ID for Athena result object expiration."
  type        = string
  default     = "expire-athena-results"
}

variable "athena_results_expiration_days" {
  description = "Days before Athena result objects expire under athena_results_prefix. Set 0 to disable."
  type        = number
  default     = 30
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


# spendsmart required iam policy for analytics, cost
variable "iam_role_name_suffix" {
  description = "Suffix for the analytics IAM role"
  type        = string
  default     = "-analytics-role"
}

variable "iam_policy_name_suffix" {
  description = "Suffix for the analytics IAM policy"
  type        = string
  default     = "-analytics-policy"
}

variable "iam_trusted_principal_type" {
  description = "Principal type allowed to assume the analytics role"
  type        = string
  default     = "AWS"
}

variable "iam_trusted_principal_identifiers" {
  description = "Principal ARNs or service principals allowed to assume the role"
  type        = list(string)
  default     = []
}
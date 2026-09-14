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

variable "bastion_enabled" {
  description = "Allow SSH to nodes from bastion security group."
  type        = bool
}

variable "bastion_security_group_id" {
  description = "Bastion security group ID from the bastion module."
  type        = string
  default     = null
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

variable "eks_node_capacity_type" {
  description = "Capacity type for node groups."
  type        = string
}

variable "eks_node_ami_type" {
  description = "AMI type for managed node groups."
  type        = string
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

variable "ec2_key_name" {
  description = "EC2 key pair name for node launch template."
  type        = string
  default     = null
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

variable "alb_enabled" {
  description = "Create an Application Load Balancer."
  type        = bool
}

variable "alb_internal" {
  description = "Create an internal ALB."
  type        = bool
}

variable "alb_allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB listener."
  type        = list(string)
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
  description = "ALB listener protocol."
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

variable "alb_ssl_policy" {
  description = "SSL policy for HTTPS listeners."
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
  description = "HTTP health-check path."
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

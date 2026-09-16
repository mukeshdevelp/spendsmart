
# General configs
aws_region     = "us-east-1"
state_file_key = "aws/infra/terraform.tfstate"
project_name   = "spendsmart"
environment    = "dev"

tags = {
  Project     = "spendsmart"
  Environment = "dev"
  ManagedBy   = "terraform"
}



# Network Module configs

availability_zones = []

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "10.0.3.0/24"]

enable_nat_gateway   = true
enable_nat_per_az    = false
enable_dns_hostnames = true
enable_dns_support   = true

internet_route_cidr = "0.0.0.0/0"



# Bastion Module configs
bastion_enabled = true

bastion_ssh_port = 22

# Replace with your trusted public IP
bastion_allowed_ssh_cidrs = [
  "0.0.0.0/0"
]

bastion_egress_cidrs = "0.0.0.0/0"

ec2_key_name = "observability.pem"

bastion_instance_type    = "t3.micro"
bastion_root_volume_size = 8
bastion_root_volume_type = "gp3"
# actual ami id
bastion_ami_ssm_parameter = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"

bastion_associate_eip = true



# EKS configs


nodes_ssh_port     = 22
nodes_egress_cidrs = ["10.0.0.0/16"]

eks_cluster_name    = "spendsmart"
eks_cluster_version = "1.36"

eks_endpoint_private_access = true
eks_endpoint_public_access  = false

eks_authentication_mode = "API_AND_CONFIG_MAP"

eks_bootstrap_cluster_creator_admin_permissions = true


# IAM roles for cluster and nodes
eks_cluster_role_name_suffix = "-eks-cluster"
eks_nodes_role_name_suffix   = "-eks-nodes"


# EKS CLUSTER IAM POLICIES
# eks_cluster_policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

# eks_vpc_resource_controller_policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"


# EKS NODE IAM POLICIES
# eks_node_worker_policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

# eks_node_cni_policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

# eks_node_ecr_policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"


# NODE CONFIGURATION
eks_node_instance_types = ["c7i-flex.large"]

eks_node_desired_size = 1
eks_node_min_size     = 1
eks_node_max_size     = 3

eks_node_disk_size = 48
eks_node_disk_type = "gp3"

eks_node_device_name = "/dev/xvda"

eks_node_volume_encrypted             = true
eks_node_volume_delete_on_termination = true


# Instance Metadata Service (IMDS) settings for EKS nodes
eks_node_metadata_http_endpoint               = "enabled"
eks_node_metadata_http_tokens                 = "required"
eks_node_metadata_http_put_response_hop_limit = 2


# Node naming configs
eks_node_launch_template_name_suffix = "-ng-"
eks_node_instance_name_suffix        = "-eks-node"
eks_node_group_tag_name_suffix       = "-node-group-"
eks_node_group_name_prefix           = "node-group-"


# Node Group
eks_node_capacity_type = "ON_DEMAND"
# AMI type
eks_node_ami_type      = "AL2023_x86_64_STANDARD"

eks_node_az_label_key = "spendsmart.io/az"

eks_node_update_max_unavailable = 1


# EKS ADDONS
eks_addons = [
  "vpc-cni",
  "kube-proxy",
  "coredns"
]


# Node security group
eks_nodes_security_group_description = "Additional security group for EKS worker nodes"

eks_nodes_security_group_name_suffix = "-eks-nodes"

eks_nodes_cluster_tag_key_prefix = "kubernetes.io/cluster/"
eks_nodes_cluster_tag_value      = "owned"

eks_nodes_self_ingress_description = "Node to node"
eks_nodes_alb_ingress_description  = "ALB to node target port"
eks_nodes_ssh_ingress_description  = "SSH from bastion"
eks_nodes_egress_description       = "Node egress"



# ALB
alb_internal = false

# Public ALB
alb_allowed_ingress_cidr = "0.0.0.0/0"


alb_security_group_name_suffix = "-alb"

alb_security_group_description = "Application Load Balancer"

alb_ingress_rule_description = "ALB listener"

alb_egress_to_nodes_description = "ALB to EKS nodes"

alb_load_balancer_type = "application"

alb_listener_port     = 80
alb_listener_protocol = "HTTP"

alb_listener_action_type = "forward"

alb_target_port = 30080 

alb_target_group_name_suffix     = "-eks"
alb_target_group_tag_name_suffix = "-eks-tg"

alb_target_group_protocol = "HTTP"

alb_health_check_path                = "/healthz"
alb_health_check_matcher             = "200-399"
alb_health_check_interval            = 30
alb_health_check_timeout             = 5
alb_health_check_healthy_threshold   = 2
alb_health_check_unhealthy_threshold = 3



# S3


bucket_name = "athena-results-spendsmart-dev"

data_prefix           = "data"
athena_results_prefix = "athena-results"

bucket_force_destroy      = false
bucket_versioning_enabled = true

bucket_sse_algorithm = "AES256"
bucket_key_enabled   = true

bucket_block_public_acls       = true
bucket_block_public_policy     = true
bucket_ignore_public_acls      = true
bucket_restrict_public_buckets = true

athena_lifecycle_rule_id       = "expire-athena-results"
athena_results_expiration_days = 30



# GLUE / ATHENA

glue_database_name          = "spendsmart_analytics"
athena_workgroup_name       = "spendsmart"
# Amazon Athena query data-scanned limit
athena_bytes_scanned_cutoff = 10737418240



# IAM Module for analytics
iam_role_name_suffix   = "-analytics-role"
iam_policy_name_suffix = "-analytics-policy"

iam_trusted_principal_type = "AWS"


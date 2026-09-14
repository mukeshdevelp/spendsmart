# env related stuff
aws_region   = "us-east-1"
project_name = "spendsmart"
environment  = "dev"
# Tags configs
tags = {
  Project     = "spendsmart"
  Environment = "dev"
  ManagedBy   = "terraform"
}

availability_zones = []

# network-skeleton module
vpc_cidr                  = "10.0.0.0/16"
public_subnet_cidrs       = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs      = ["10.0.2.0/24", "10.0.3.0/24"]
enable_nat_gateway        = true
enable_nat_per_az         = false
enable_dns_hostnames      = true
enable_dns_support        = true
internet_route_cidr       = "0.0.0.0/0"
bastion_enabled           = true
bastion_ssh_port          = 22
bastion_allowed_ssh_cidrs = ["0.0.0.0/0"]
bastion_egress_cidrs      = ["0.0.0.0/0"]

# Existing EC2 key pair in this AWS account and region. Terraform looks it up
# and attaches it to the bastion and all EKS worker nodes.
ec2_key_name = "observability.pem"

# Bastion config (bastion module)
bastion_instance_type     = "t3.micro"
bastion_root_volume_size  = 8
bastion_root_volume_type  = "gp3"
bastion_ami_ssm_parameter = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
bastion_associate_eip     = true
ec2_ssm_policy_arn        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

# eks module
sg_protocol_tcp                                 = "tcp"
sg_protocol_all                                 = "-1"
nodes_ssh_port                                  = 22
nodes_egress_cidrs                              = ["10.0.0.0/16"]
eks_cluster_name                                = "spendsmart"
eks_cluster_version                             = "1.31"
eks_endpoint_private_access                     = true
eks_endpoint_public_access                      = false
eks_public_access_cidrs                         = []
eks_authentication_mode                         = "API_AND_CONFIG_MAP"
eks_bootstrap_cluster_creator_admin_permissions = true
eks_assume_role_action                          = "sts:AssumeRole"
eks_cluster_assume_role_principal_type          = "Service"
eks_cluster_assume_role_service                 = "eks.amazonaws.com"
eks_node_assume_role_principal_type             = "Service"
eks_node_assume_role_service                    = "ec2.amazonaws.com"
eks_cluster_role_name_suffix                    = "-eks-cluster"
eks_nodes_role_name_suffix                      = "-eks-nodes"
eks_cluster_policy_arn                          = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
eks_vpc_resource_controller_policy_arn          = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
eks_node_worker_policy_arn                      = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
eks_node_cni_policy_arn                         = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
eks_node_ecr_policy_arn                         = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
eks_node_ssm_policy_arn                         = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
eks_node_instance_types                         = ["c7i-flex.large"]
eks_node_desired_size                           = 1
eks_node_min_size                               = 1
eks_node_max_size                               = 3
eks_node_disk_size                              = 48
eks_node_disk_type                              = "gp3"
eks_node_device_name                            = "/dev/xvda"
eks_node_volume_encrypted                       = true
eks_node_volume_delete_on_termination           = true
eks_node_metadata_http_endpoint                 = "enabled"
eks_node_metadata_http_tokens                   = "required"
eks_node_metadata_http_put_response_hop_limit   = 2
eks_node_instance_tag_resource_type             = "instance"
eks_node_launch_template_name_suffix            = "-ng-"
eks_node_instance_name_suffix                   = "-eks-node"
eks_node_group_tag_name_suffix                  = "-node-group-"
eks_node_capacity_type                          = "ON_DEMAND"
eks_node_ami_type                               = "AL2023_x86_64_STANDARD"
eks_node_group_name_prefix                      = "node-group-"
eks_node_az_label_key                           = "spendsmart.io/az"
eks_node_update_max_unavailable                 = 1
eks_addons                                      = ["vpc-cni", "kube-proxy", "coredns"]
eks_nodes_security_group_description            = "Additional security group for EKS worker nodes"
eks_nodes_security_group_name_suffix            = "-eks-nodes"
eks_nodes_cluster_tag_key_prefix                = "kubernetes.io/cluster/"
eks_nodes_cluster_tag_value                     = "owned"
eks_nodes_self_ingress_description              = "Node to node"
eks_nodes_alb_ingress_description               = "ALB to node target port"
eks_nodes_ssh_ingress_description               = "SSH from bastion"
eks_nodes_egress_description                    = "Node egress"
alb_enabled                                     = true
alb_internal                                    = false
alb_allowed_ingress_cidrs                       = ["10.0.0.0/16"]
alb_security_group_name_suffix                  = "-alb"
alb_security_group_description                  = "Application Load Balancer"
alb_ingress_rule_description                    = "ALB listener"
alb_egress_to_nodes_description                 = "ALB to EKS nodes"
alb_load_balancer_type                          = "application"
alb_listener_port                               = 80
alb_listener_protocol                           = "HTTP"
alb_listener_protocol_https                     = "HTTPS"
alb_listener_action_type                        = "forward"
alb_ssl_policy                                  = "ELBSecurityPolicy-TLS13-1-2-2021-06"
alb_certificate_arn                             = ""
alb_target_port                                 = 30080
alb_target_group_name_suffix                    = "-eks"
alb_target_group_tag_name_suffix                = "-eks-tg"
alb_target_group_protocol                       = "HTTP"
alb_health_check_enabled                        = true
alb_health_check_path                           = "/healthz"
alb_health_check_matcher                        = "200-399"
alb_health_check_interval                       = 30
alb_health_check_timeout                        = 5
alb_health_check_healthy_threshold              = 2
alb_health_check_unhealthy_threshold            = 3

# s3 module
# Leave empty to derive a globally unique name: spendsmart-dev-<account-id>.
bucket_name                    = ""
data_prefix                    = "data"
athena_results_prefix          = "athena-results"
bucket_force_destroy           = false
bucket_versioning_enabled      = true
bucket_sse_algorithm           = "AES256"
bucket_key_enabled             = true
bucket_block_public_acls       = true
bucket_block_public_policy     = true
bucket_ignore_public_acls      = true
bucket_restrict_public_buckets = true
athena_lifecycle_rule_id       = "expire-athena-results"
athena_results_expiration_days = 30

# glue related configs
glue_database_name          = "spendsmart_analytics"
athena_workgroup_name       = "spendsmart"
athena_bytes_scanned_cutoff = 10737418240

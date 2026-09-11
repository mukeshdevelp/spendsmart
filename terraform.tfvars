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
# VPC  and subent related configs
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "10.0.3.0/24"]

# Nacl related configs
enable_nodes_nacl                        = true
nodes_nacl_ingress_from_public_tcp_ports = [22, 30080]
nodes_nacl_ingress_allow_vpc             = true
nodes_nacl_ephemeral_from_port           = 1024
nodes_nacl_ephemeral_to_port             = 65535
nodes_nacl_ephemeral_protocols           = ["tcp", "udp"]
nodes_nacl_egress_internet_tcp_ports     = [80, 443, 53]
nodes_nacl_egress_internet_udp_ports     = [53]
nodes_nacl_egress_allow_vpc              = true

# NAT gateway configs
enable_nat_gateway   = true
enable_nat_per_az    = false
enable_dns_hostnames = true
enable_dns_support   = true

# SSH key created in AWS (EC2 CreateKeyPair); private key PEM stored in Secrets Manager
create_ssh_key                      = true
ssh_key_name                        = ""
ssh_private_key_secret_name         = ""
ssh_key_secret_recovery_window_days = 7

# Bastion config
bastion_enabled           = true
bastion_instance_type     = "t3.micro"
bastion_key_name          = ""
bastion_allowed_ssh_cidrs = ["0.0.0.0/0"]
bastion_associate_eip     = true

# Clickhouse configs
clickhouse_enabled          = true
clickhouse_instance_type    = "m6i.large"
clickhouse_root_volume_size = 50
clickhouse_data_volume_size = 200
clickhouse_http_port        = 8123
clickhouse_native_port      = 9000

# Cluster and node configs
eks_cluster_name              = "spendsmart"
eks_cluster_version           = "1.31"
eks_endpoint_private_access   = true
eks_endpoint_public_access    = true
eks_public_access_cidrs       = ["0.0.0.0/0"]
eks_enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
eks_node_instance_types       = ["c6i.xlarge"]
eks_node_desired_size         = 1
eks_node_min_size             = 1
eks_node_max_size             = 3
eks_node_disk_size            = 48
eks_node_capacity_type        = "ON_DEMAND"
eks_node_ami_type             = "AL2023_x86_64_STANDARD"

# ALB configs
alb_enabled              = true
alb_internal             = false
alb_listener_port        = 80
alb_listener_protocol    = "HTTP"
alb_certificate_arn      = ""
alb_target_port          = 30080
alb_health_check_path    = "/healthz"
alb_health_check_matcher = "200-399"

# Route53 configs
create_route53_zone = true
route53_zone_id     = ""
domain_name         = "spendsmart.example.com"
app_hostname        = "app.spendsmart.example.com"

# Athena and Glue related configs
data_bucket_name            = ""
athena_results_bucket_name  = ""
glue_database_name          = "spendsmart_analytics"
athena_workgroup_name       = "spendsmart"
athena_bytes_scanned_cutoff = 10737418240

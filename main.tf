locals {
  name_prefix = "${var.project_name}-${var.environment}"

  data_bucket_name = var.data_bucket_name != "" ? var.data_bucket_name : "${var.project_name}-${var.environment}-data"

  athena_results_bucket_name = var.athena_results_bucket_name != "" ? var.athena_results_bucket_name : "${var.project_name}-${var.environment}-athena"
}

module "networking" {
  source = "./networking"

  name_prefix                              = local.name_prefix
  vpc_cidr                                 = var.vpc_cidr
  availability_zones                       = var.availability_zones
  public_subnet_cidrs                      = var.public_subnet_cidrs
  private_subnet_cidrs                     = var.private_subnet_cidrs
  eks_cluster_name                         = var.eks_cluster_name
  enable_nat_gateway                       = var.enable_nat_gateway
  enable_nat_per_az                        = var.enable_nat_per_az
  enable_dns_hostnames                     = var.enable_dns_hostnames
  enable_dns_support                       = var.enable_dns_support
  enable_nodes_nacl                        = var.enable_nodes_nacl
  nodes_nacl_ingress_from_public_tcp_ports = var.nodes_nacl_ingress_from_public_tcp_ports
  nodes_nacl_ingress_allow_vpc             = var.nodes_nacl_ingress_allow_vpc
  nodes_nacl_ephemeral_from_port           = var.nodes_nacl_ephemeral_from_port
  nodes_nacl_ephemeral_to_port             = var.nodes_nacl_ephemeral_to_port
  nodes_nacl_ephemeral_protocols           = var.nodes_nacl_ephemeral_protocols
  nodes_nacl_egress_internet_tcp_ports     = var.nodes_nacl_egress_internet_tcp_ports
  nodes_nacl_egress_internet_udp_ports     = var.nodes_nacl_egress_internet_udp_ports
  nodes_nacl_egress_allow_vpc              = var.nodes_nacl_egress_allow_vpc
}

module "security" {
  source = "./security"

  vpc_id                              = module.networking.vpc_id
  vpc_cidr                            = module.networking.vpc_cidr
  public_subnet_cidrs                 = var.public_subnet_cidrs
  name_prefix                         = local.name_prefix
  aws_region                          = var.aws_region
  bastion_enabled                     = var.bastion_enabled
  bastion_allowed_ssh_cidrs           = var.bastion_allowed_ssh_cidrs
  alb_enabled                         = var.alb_enabled
  alb_target_port                     = var.alb_target_port
  clickhouse_enabled                  = var.clickhouse_enabled
  clickhouse_http_port                = var.clickhouse_http_port
  clickhouse_native_port              = var.clickhouse_native_port
  eks_cluster_name                    = var.eks_cluster_name
  create_ssh_key                      = var.create_ssh_key
  ssh_key_name                        = var.ssh_key_name
  ssh_private_key_secret_name         = var.ssh_private_key_secret_name
  ssh_key_secret_recovery_window_days = var.ssh_key_secret_recovery_window_days
  bastion_key_name                    = var.bastion_key_name

  depends_on = [module.networking]
}

module "ec2" {
  source = "./ec2"

  name_prefix                   = local.name_prefix
  bastion_enabled               = var.bastion_enabled
  bastion_instance_type         = var.bastion_instance_type
  bastion_associate_eip         = var.bastion_associate_eip
  public_subnet_id              = module.networking.first_public_subnet_id
  bastion_security_group_id     = module.security.bastion_security_group_id
  ec2_ssm_instance_profile_name = module.security.ec2_ssm_instance_profile_name
  ec2_key_name                  = module.security.ec2_key_name

  depends_on = [module.networking, module.security]
}

module "db" {
  source = "./db"

  name_prefix                   = local.name_prefix
  clickhouse_enabled            = var.clickhouse_enabled
  clickhouse_instance_type      = var.clickhouse_instance_type
  clickhouse_root_volume_size   = var.clickhouse_root_volume_size
  clickhouse_data_volume_size   = var.clickhouse_data_volume_size
  private_subnet_id             = module.networking.first_private_subnet_id
  clickhouse_security_group_id  = module.security.clickhouse_security_group_id
  ec2_ssm_instance_profile_name = module.security.ec2_ssm_instance_profile_name
  ec2_key_name                  = module.security.ec2_key_name

  depends_on = [module.networking, module.security]
}

module "monitoring" {
  source = "./monitoring"

  eks_cluster_name = var.eks_cluster_name
}

module "eks" {
  source = "./eks"

  name_prefix                   = local.name_prefix
  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = values(module.networking.private_subnet_ids)
  private_subnet_map            = module.networking.private_subnet_map
  public_subnet_ids             = values(module.networking.public_subnet_ids)
  eks_cluster_name              = var.eks_cluster_name
  eks_cluster_version           = var.eks_cluster_version
  eks_endpoint_private_access   = var.eks_endpoint_private_access
  eks_endpoint_public_access    = var.eks_endpoint_public_access
  eks_public_access_cidrs       = var.eks_public_access_cidrs
  eks_enabled_cluster_log_types = var.eks_enabled_cluster_log_types
  log_group_name                = module.monitoring.eks_log_group_name
  eks_node_instance_types       = var.eks_node_instance_types
  eks_node_desired_size         = var.eks_node_desired_size
  eks_node_min_size             = var.eks_node_min_size
  eks_node_max_size             = var.eks_node_max_size
  eks_node_disk_size            = var.eks_node_disk_size
  eks_node_capacity_type        = var.eks_node_capacity_type
  eks_node_ami_type             = var.eks_node_ami_type
  ec2_key_name                  = module.security.ec2_key_name
  eks_nodes_security_group_id   = module.security.eks_nodes_security_group_id
  alb_enabled                   = var.alb_enabled
  alb_internal                  = var.alb_internal
  alb_security_group_id         = module.security.alb_security_group_id
  alb_listener_port             = var.alb_listener_port
  alb_listener_protocol         = var.alb_listener_protocol
  alb_certificate_arn           = var.alb_certificate_arn
  alb_target_port               = var.alb_target_port
  alb_health_check_path         = var.alb_health_check_path
  alb_health_check_matcher      = var.alb_health_check_matcher
  create_route53_zone           = var.create_route53_zone
  route53_zone_id               = var.route53_zone_id
  domain_name                   = var.domain_name
  app_hostname                  = var.app_hostname

  depends_on = [module.networking, module.security, module.monitoring]
}

module "glue" {
  source = "./glue"

  name_prefix        = local.name_prefix
  data_bucket_name   = local.data_bucket_name
  glue_database_name = var.glue_database_name
}

module "athena" {
  source = "./athena"

  athena_results_bucket_name  = local.athena_results_bucket_name
  athena_workgroup_name       = var.athena_workgroup_name
  athena_bytes_scanned_cutoff = var.athena_bytes_scanned_cutoff
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  bucket_name           = var.bucket_name != "" ? var.bucket_name : "${var.project_name}-${var.environment}"
  data_prefix           = "data"
  athena_results_prefix = "athena-results"

  ssh_private_key_secret_name = var.ssh_private_key_secret_name != "" ? var.ssh_private_key_secret_name : "${local.name_prefix}-ssh-private-key"
}

module "network_skeleton" {
  source = "./modules/network-skeleton"

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

module "bastion" {
  source = "./modules/bastion"

  name_prefix                         = local.name_prefix
  vpc_id                              = module.network_skeleton.vpc_id
  aws_region                          = var.aws_region
  public_subnet_id                    = module.network_skeleton.first_public_subnet_id
  private_subnet_id                   = module.network_skeleton.first_private_subnet_id
  bastion_enabled                     = var.bastion_enabled
  bastion_instance_type               = var.bastion_instance_type
  bastion_associate_eip               = var.bastion_associate_eip
  bastion_allowed_ssh_cidrs           = var.bastion_allowed_ssh_cidrs
  create_ssh_key                      = var.create_ssh_key
  ssh_key_name                        = var.ssh_key_name
  ssh_private_key_secret_name         = var.ssh_private_key_secret_name
  ssh_key_secret_recovery_window_days = var.ssh_key_secret_recovery_window_days
  bastion_key_name                    = var.bastion_key_name
  clickhouse_enabled                  = var.clickhouse_enabled
  clickhouse_instance_type            = var.clickhouse_instance_type
  clickhouse_root_volume_size         = var.clickhouse_root_volume_size
  clickhouse_data_volume_size         = var.clickhouse_data_volume_size
  clickhouse_http_port                = var.clickhouse_http_port
  clickhouse_native_port              = var.clickhouse_native_port

  depends_on = [module.network_skeleton]
}

module "eks" {
  source = "./modules/eks"

  name_prefix                   = local.name_prefix
  vpc_id                        = module.network_skeleton.vpc_id
  private_subnet_ids            = values(module.network_skeleton.private_subnet_ids)
  private_subnet_map            = module.network_skeleton.private_subnet_map
  public_subnet_ids             = values(module.network_skeleton.public_subnet_ids)
  eks_cluster_name              = var.eks_cluster_name
  eks_cluster_version           = var.eks_cluster_version
  eks_endpoint_private_access   = var.eks_endpoint_private_access
  eks_endpoint_public_access    = var.eks_endpoint_public_access
  eks_public_access_cidrs       = var.eks_public_access_cidrs
  eks_node_instance_types       = var.eks_node_instance_types
  eks_node_desired_size         = var.eks_node_desired_size
  eks_node_min_size             = var.eks_node_min_size
  eks_node_max_size             = var.eks_node_max_size
  eks_node_disk_size            = var.eks_node_disk_size
  eks_node_capacity_type        = var.eks_node_capacity_type
  eks_node_ami_type             = var.eks_node_ami_type
  ec2_key_name                  = module.bastion.ec2_key_name
  bastion_enabled               = var.bastion_enabled
  bastion_security_group_id     = module.bastion.bastion_security_group_id
  clickhouse_enabled            = var.clickhouse_enabled
  clickhouse_security_group_id  = module.bastion.clickhouse_security_group_id
  clickhouse_http_port          = var.clickhouse_http_port
  clickhouse_native_port        = var.clickhouse_native_port
  alb_enabled                   = var.alb_enabled
  alb_internal                  = var.alb_internal
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

  depends_on = [module.network_skeleton, module.bastion]
}

module "s3" {
  source = "./modules/s3"

  bucket_name           = local.bucket_name
  data_prefix           = local.data_prefix
  athena_results_prefix = local.athena_results_prefix
}

module "glue" {
  source = "./modules/glue"

  name_prefix        = local.name_prefix
  bucket_arn         = module.s3.bucket_arn
  data_prefix        = module.s3.data_prefix
  glue_database_name = var.glue_database_name

  depends_on = [module.s3]
}

module "athena" {
  source = "./modules/athena"

  athena_output_location      = module.s3.athena_output_location
  athena_workgroup_name       = var.athena_workgroup_name
  athena_bytes_scanned_cutoff = var.athena_bytes_scanned_cutoff

  depends_on = [module.s3]
}

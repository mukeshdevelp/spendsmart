module "network_skeleton" {
  source = "./modules/network-skeleton"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  eks_cluster_name     = var.eks_cluster_name
  enable_nat_gateway   = var.enable_nat_gateway
  enable_nat_per_az    = var.enable_nat_per_az
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  internet_route_cidr  = var.internet_route_cidr
}

module "bastion" {
  source = "./modules/bastion"

  name_prefix = local.name_prefix
  vpc_id      = module.network_skeleton.vpc_id

  public_subnet_id = module.network_skeleton.first_public_subnet_id

  bastion_enabled = var.bastion_enabled

  bastion_instance_type     = var.bastion_instance_type
  bastion_root_volume_size  = var.bastion_root_volume_size
  bastion_root_volume_type  = var.bastion_root_volume_type
  bastion_ami_ssm_parameter = var.bastion_ami_ssm_parameter

  bastion_associate_eip = var.bastion_associate_eip

  ec2_key_name = var.ec2_key_name

  ec2_ssm_policy_arn = var.ec2_ssm_policy_arn

  bastion_ssh_port          = var.bastion_ssh_port
  bastion_allowed_ssh_cidrs = var.bastion_allowed_ssh_cidrs
  bastion_egress_cidrs      = var.bastion_egress_cidrs

  depends_on = [module.network_skeleton]
}

module "eks" {
  source = "./modules/eks"

  name_prefix                                     = local.name_prefix
  vpc_id                                          = module.network_skeleton.vpc_id
  private_subnet_ids                              = values(module.network_skeleton.private_subnet_ids)
  private_subnet_map                              = module.network_skeleton.private_subnet_map
  public_subnet_ids                               = values(module.network_skeleton.public_subnet_ids)
  bastion_enabled                                 = var.bastion_enabled
  bastion_security_group_id                       = module.bastion.bastion_security_group_id
  nodes_ssh_port                                  = var.nodes_ssh_port
  nodes_egress_cidrs                              = var.nodes_egress_cidrs
  sg_protocol_tcp                                 = var.sg_protocol_tcp
  sg_protocol_all                                 = var.sg_protocol_all
  eks_cluster_name                                = var.eks_cluster_name
  eks_cluster_version                             = var.eks_cluster_version
  eks_endpoint_private_access                     = var.eks_endpoint_private_access
  eks_endpoint_public_access                      = var.eks_endpoint_public_access
  eks_public_access_cidrs                         = var.eks_public_access_cidrs
  eks_authentication_mode                         = var.eks_authentication_mode
  eks_bootstrap_cluster_creator_admin_permissions = var.eks_bootstrap_cluster_creator_admin_permissions
  eks_assume_role_action                          = var.eks_assume_role_action
  eks_cluster_assume_role_principal_type          = var.eks_cluster_assume_role_principal_type
  eks_cluster_assume_role_service                 = var.eks_cluster_assume_role_service
  eks_node_assume_role_principal_type             = var.eks_node_assume_role_principal_type
  eks_node_assume_role_service                    = var.eks_node_assume_role_service
  eks_cluster_role_name_suffix                    = var.eks_cluster_role_name_suffix
  eks_nodes_role_name_suffix                      = var.eks_nodes_role_name_suffix
  eks_cluster_policy_arn                          = var.eks_cluster_policy_arn
  eks_vpc_resource_controller_policy_arn          = var.eks_vpc_resource_controller_policy_arn
  eks_node_worker_policy_arn                      = var.eks_node_worker_policy_arn
  eks_node_cni_policy_arn                         = var.eks_node_cni_policy_arn
  eks_node_ecr_policy_arn                         = var.eks_node_ecr_policy_arn
  eks_node_ssm_policy_arn                         = var.eks_node_ssm_policy_arn
  eks_node_instance_types                         = var.eks_node_instance_types
  eks_node_desired_size                           = var.eks_node_desired_size
  eks_node_min_size                               = var.eks_node_min_size
  eks_node_max_size                               = var.eks_node_max_size
  eks_node_disk_size                              = var.eks_node_disk_size
  eks_node_disk_type                              = var.eks_node_disk_type
  eks_node_device_name                            = var.eks_node_device_name
  eks_node_volume_encrypted                       = var.eks_node_volume_encrypted
  eks_node_volume_delete_on_termination           = var.eks_node_volume_delete_on_termination
  eks_node_metadata_http_endpoint                 = var.eks_node_metadata_http_endpoint
  eks_node_metadata_http_tokens                   = var.eks_node_metadata_http_tokens
  eks_node_metadata_http_put_response_hop_limit   = var.eks_node_metadata_http_put_response_hop_limit
  eks_node_instance_tag_resource_type             = var.eks_node_instance_tag_resource_type
  eks_node_launch_template_name_suffix            = var.eks_node_launch_template_name_suffix
  eks_node_instance_name_suffix                   = var.eks_node_instance_name_suffix
  eks_node_group_tag_name_suffix                  = var.eks_node_group_tag_name_suffix
  eks_node_capacity_type                          = var.eks_node_capacity_type
  eks_node_ami_type                               = var.eks_node_ami_type
  eks_node_group_name_prefix                      = var.eks_node_group_name_prefix
  eks_node_az_label_key                           = var.eks_node_az_label_key
  eks_node_update_max_unavailable                 = var.eks_node_update_max_unavailable
  eks_addons                                      = var.eks_addons
  ec2_key_name                                    = module.bastion.ec2_key_name
  eks_nodes_security_group_description            = var.eks_nodes_security_group_description
  eks_nodes_security_group_name_suffix            = var.eks_nodes_security_group_name_suffix
  eks_nodes_cluster_tag_key_prefix                = var.eks_nodes_cluster_tag_key_prefix
  eks_nodes_cluster_tag_value                     = var.eks_nodes_cluster_tag_value
  eks_nodes_self_ingress_description              = var.eks_nodes_self_ingress_description
  eks_nodes_alb_ingress_description               = var.eks_nodes_alb_ingress_description
  eks_nodes_ssh_ingress_description               = var.eks_nodes_ssh_ingress_description
  eks_nodes_egress_description                    = var.eks_nodes_egress_description
  alb_enabled                                     = var.alb_enabled
  alb_internal                                    = var.alb_internal
  alb_allowed_ingress_cidr                        = var.alb_allowed_ingress_cidr
  alb_security_group_name_suffix                  = var.alb_security_group_name_suffix
  alb_security_group_description                  = var.alb_security_group_description
  alb_ingress_rule_description                    = var.alb_ingress_rule_description
  alb_egress_to_nodes_description                 = var.alb_egress_to_nodes_description
  alb_load_balancer_type                          = var.alb_load_balancer_type
  alb_listener_port                               = var.alb_listener_port
  alb_listener_protocol                           = var.alb_listener_protocol
  alb_listener_protocol_https                     = var.alb_listener_protocol_https
  alb_listener_action_type                        = var.alb_listener_action_type
  alb_ssl_policy                                  = var.alb_ssl_policy
  alb_certificate_arn                             = var.alb_certificate_arn
  alb_target_port                                 = var.alb_target_port
  alb_target_group_name_suffix                    = var.alb_target_group_name_suffix
  alb_target_group_tag_name_suffix                = var.alb_target_group_tag_name_suffix
  alb_target_group_protocol                       = var.alb_target_group_protocol
  alb_health_check_enabled                        = var.alb_health_check_enabled
  alb_health_check_path                           = var.alb_health_check_path
  alb_health_check_matcher                        = var.alb_health_check_matcher
  alb_health_check_interval                       = var.alb_health_check_interval
  alb_health_check_timeout                        = var.alb_health_check_timeout
  alb_health_check_healthy_threshold              = var.alb_health_check_healthy_threshold
  alb_health_check_unhealthy_threshold            = var.alb_health_check_unhealthy_threshold

  depends_on = [module.network_skeleton, module.bastion]
}

module "s3" {
  source = "./modules/s3"

  bucket_name                    = local.bucket_name
  data_prefix                    = var.data_prefix
  athena_results_prefix          = var.athena_results_prefix
  force_destroy                  = var.bucket_force_destroy
  versioning_enabled             = var.bucket_versioning_enabled
  sse_algorithm                  = var.bucket_sse_algorithm
  bucket_key_enabled             = var.bucket_key_enabled
  block_public_acls              = var.bucket_block_public_acls
  block_public_policy            = var.bucket_block_public_policy
  ignore_public_acls             = var.bucket_ignore_public_acls
  restrict_public_buckets        = var.bucket_restrict_public_buckets
  athena_lifecycle_rule_id       = var.athena_lifecycle_rule_id
  athena_results_expiration_days = var.athena_results_expiration_days
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
/*
# IAM module call
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment

  iam_role_name_suffix   = var.iam_role_name_suffix
  iam_policy_name_suffix = var.iam_policy_name_suffix

  trusted_principal_type        = var.iam_trusted_principal_type
  trusted_principal_identifiers = var.iam_trusted_principal_identifiers

  tags = var.tags
}
*/
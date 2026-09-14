locals {
  eks_cluster_role_name           = "${var.name_prefix}${var.eks_cluster_role_name_suffix}"
  eks_nodes_role_name             = "${var.name_prefix}${var.eks_nodes_role_name_suffix}"
  eks_node_launch_template_prefix = "${var.name_prefix}${var.eks_node_launch_template_name_suffix}"
  eks_node_instance_name          = "${var.name_prefix}${var.eks_node_instance_name_suffix}"
  eks_node_group_tag_name         = "${var.name_prefix}${var.eks_node_group_tag_name_suffix}"
  alb_security_group_name         = "${var.name_prefix}${var.alb_security_group_name_suffix}"
  eks_nodes_security_group_name   = "${var.name_prefix}${var.eks_nodes_security_group_name_suffix}"
  eks_nodes_cluster_tag_key       = "${var.eks_nodes_cluster_tag_key_prefix}${var.eks_cluster_name}"
  alb_name                        = "${var.name_prefix}${var.alb_security_group_name_suffix}"
  alb_target_group_name           = "${var.name_prefix}${var.alb_target_group_name_suffix}"
  alb_target_group_tag_name       = "${var.name_prefix}${var.alb_target_group_tag_name_suffix}"
}
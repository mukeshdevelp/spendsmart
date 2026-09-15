# EKS CLUSTER IAM ROLE
 
# generates trust policy JSON
data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}
# creating a role with the above create policy document
resource "aws_iam_role" "eks_cluster" {
  name               = local.eks_cluster_role_name
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json
}

# attaching the managed policy to the role
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = var.eks_cluster_policy_arn
}
# attaching vpc controller policy to the role
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = var.eks_vpc_resource_controller_policy_arn
}


 
# EKS NODE IAM ROLE
 
# generates trust policy JSON for node
data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
# create a role with above policy document
resource "aws_iam_role" "eks_nodes" {
  name               = local.eks_nodes_role_name
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json
}
# attaching the managed policy to the role
resource "aws_iam_role_policy_attachment" "eks_worker" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = var.eks_node_worker_policy_arn
}
# attaches the AWS CNI permissions policy to your EKS worker-node IAM role
resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = var.eks_node_cni_policy_arn
}

# attaches the AmazonEC2ContainerRegistryReadOnly policy to your EKS worker-node IAM role
resource "aws_iam_role_policy_attachment" "eks_ecr" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = var.eks_node_ecr_policy_arn
}


 
# EKS CLUSTER
 
# cluster
resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_cluster_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.eks_endpoint_private_access
    endpoint_public_access  = var.eks_endpoint_public_access
  }

  access_config {
    authentication_mode                         = var.eks_authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.eks_bootstrap_cluster_creator_admin_permissions
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]
}


 
# EKS NODE SECURITY GROUP
 
# security group for EKS nodes
resource "aws_security_group" "eks_nodes" {
  name        = local.eks_nodes_security_group_name
  description = var.eks_nodes_security_group_description
  vpc_id      = var.vpc_id

  tags = {
    Name                              = local.eks_nodes_security_group_name
    (local.eks_nodes_cluster_tag_key) = var.eks_nodes_cluster_tag_value
  }
}
# security group ingress for node to node communication
resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = var.eks_nodes_self_ingress_description
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}
# security group ingress for node - allows ssh access from bastion to nodes
resource "aws_vpc_security_group_ingress_rule" "nodes_ssh_from_bastion" {
  # count = var.bastion_enabled ? 1 : 0

  security_group_id            = aws_security_group.eks_nodes.id
  description                  = var.eks_nodes_ssh_ingress_description
  ip_protocol                  = "tcp"
  from_port                    = var.nodes_ssh_port
  to_port                      = var.nodes_ssh_port
  referenced_security_group_id = var.bastion_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "nodes_egress" {
  for_each = toset(var.nodes_egress_cidrs)

  security_group_id = aws_security_group.eks_nodes.id
  description       = var.eks_nodes_egress_description
  ip_protocol       = "-1"
  cidr_ipv4         = each.value
}


 
# ALB SECURITY GROUP
 

resource "aws_security_group" "alb" {
  name        = local.alb_security_group_name
  description = var.alb_security_group_description
  vpc_id      = var.vpc_id

  tags = {
    Name = local.alb_security_group_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_listener" {

  security_group_id = aws_security_group.alb.id
  description       = var.alb_ingress_rule_description
  ip_protocol       = "tcp"
  from_port         = var.alb_listener_port
  to_port           = var.alb_listener_port
  cidr_ipv4         = var.alb_allowed_ingress_cidr

}

resource "aws_vpc_security_group_egress_rule" "alb_to_nodes" {
  security_group_id            = aws_security_group.alb.id
  description                  = var.alb_egress_to_nodes_description
  ip_protocol                  = "tcp"
  from_port                    = var.alb_target_port
  to_port                      = var.alb_target_port
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = var.eks_nodes_alb_ingress_description
  ip_protocol                  = "tcp"
  from_port                    = var.alb_target_port
  to_port                      = var.alb_target_port
  referenced_security_group_id = aws_security_group.alb.id
}


 
# EKS NODE LAUNCH TEMPLATE
 

resource "aws_launch_template" "eks_nodes" {
  name_prefix = local.eks_node_launch_template_prefix

  key_name = var.ec2_key_name

  vpc_security_group_ids = [
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
    aws_security_group.eks_nodes.id
  ]

  block_device_mappings {
    device_name = var.eks_node_device_name

    ebs {
      volume_size           = var.eks_node_disk_size
      volume_type           = var.eks_node_disk_type
      encrypted             = var.eks_node_volume_encrypted
      delete_on_termination = var.eks_node_volume_delete_on_termination
    }
  }

  metadata_options {
    http_endpoint               = var.eks_node_metadata_http_endpoint
    http_tokens                 = var.eks_node_metadata_http_tokens
    http_put_response_hop_limit = var.eks_node_metadata_http_put_response_hop_limit
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.eks_node_instance_name
    }
  }
}


 
# EKS NODE GROUPS
 

resource "aws_eks_node_group" "this" {
  for_each = var.private_subnet_map

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.eks_node_group_name_prefix}${each.value.index}"
  node_role_arn   = aws_iam_role.eks_nodes.arn

  subnet_ids     = [each.value.id]
  instance_types = var.eks_node_instance_types
  ami_type       = var.eks_node_ami_type
  capacity_type  = var.eks_node_capacity_type

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  scaling_config {
    desired_size = var.eks_node_desired_size
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  update_config {
    max_unavailable = var.eks_node_update_max_unavailable
  }

  labels = {
    (var.eks_node_az_label_key) = each.value.az
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr
  ]

  tags = {
    Name = "${local.eks_node_group_tag_name}${each.value.index}"
  }
}


 
# EKS ADDONS
 

resource "aws_eks_addon" "this" {
  for_each = toset(var.eks_addons)

  cluster_name = aws_eks_cluster.this.name
  addon_name   = each.value

  depends_on = [aws_eks_node_group.this]
}


 
# APPLICATION LOAD BALANCER
 

resource "aws_lb" "load_balancer" {
  name               = local.alb_name
  internal           = var.alb_internal
  load_balancer_type = var.alb_load_balancer_type
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = local.alb_name
  }
}

resource "aws_lb_target_group" "target_group_eks" {
  name     = local.alb_target_group_name
  port     = var.alb_target_port
  protocol = var.alb_target_group_protocol
  vpc_id   = var.vpc_id

  health_check {
    path                = var.alb_health_check_path
    matcher             = var.alb_health_check_matcher
    interval            = var.alb_health_check_interval
    timeout             = var.alb_health_check_timeout
    healthy_threshold   = var.alb_health_check_healthy_threshold
    unhealthy_threshold = var.alb_health_check_unhealthy_threshold
  }

  tags = {
    Name = local.alb_target_group_tag_name
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = var.alb_listener_port
  protocol          = var.alb_listener_protocol

  default_action {
    type             = var.alb_listener_action_type
    target_group_arn = aws_lb_target_group.target_group_eks.arn
  }
}
data "aws_cloudwatch_log_group" "eks" {
  name = var.log_group_name
}

locals {
  route53_zone_id = var.create_route53_zone ? aws_route53_zone.this[0].zone_id : var.route53_zone_id
}

# cluster policy document
data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}
# iam role for eks cluster
resource "aws_iam_role" "eks_cluster" {
  name               = "${var.name_prefix}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json
}

# iam policy attachment for eks cluster
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
# iam policy attachment for vpc resource controller
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# EKS cluster
resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_cluster_version

  enabled_cluster_log_types = var.eks_enabled_cluster_log_types

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.eks_endpoint_private_access
    endpoint_public_access  = var.eks_endpoint_public_access
    public_access_cidrs     = var.eks_public_access_cidrs
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
    data.aws_cloudwatch_log_group.eks,
  ]
}

# EKS node policy doc
data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
# iam role for EKS nodes
resource "aws_iam_role" "eks_nodes" {
  name               = "${var.name_prefix}-eks-nodes"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json
}
# iam role for workers EKS
resource "aws_iam_role_policy_attachment" "eks_worker" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# EKS CNI policy attachment
resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ECR Policy attachment
resource "aws_iam_role_policy_attachment" "eks_ecr" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
# EKS ssm policy attachement
resource "aws_iam_role_policy_attachment" "eks_ssm" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# launch template for EKS nodes
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.name_prefix}-ng-"

  key_name = var.ec2_key_name

  vpc_security_group_ids = [
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
    var.eks_nodes_security_group_id,
  ]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.eks_node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-eks-node"
    }
  }
}
# Node Group Creation
resource "aws_eks_node_group" "this" {
  for_each = var.private_subnet_map

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "node-group-${each.value.index}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [each.value.id]
  instance_types  = var.eks_node_instance_types
  ami_type        = var.eks_node_ami_type
  capacity_type   = var.eks_node_capacity_type

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
    max_unavailable = 1
  }

  labels = {
    "spendsmart.io/az" = each.value.az
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr,
    aws_iam_role_policy_attachment.eks_ssm,
  ]

  tags = {
    Name = "${var.name_prefix}-node-group-${each.value.index}"
  }
}
# EKS addons - vpc cni
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  depends_on = [aws_eks_node_group.this]
}
# EKS addon - kube-proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  depends_on = [aws_eks_node_group.this]
}
# EKS addon - coredns
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"

  depends_on = [aws_eks_node_group.this]
}

# load balancer
resource "aws_lb" "load_balancer" {
  count = var.alb_enabled ? 1 : 0

  name               = "${var.name_prefix}-alb"
  internal           = var.alb_internal
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "target_group_eks" {
  count = var.alb_enabled ? 1 : 0

  name     = "${var.name_prefix}-eks"
  port     = var.alb_target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = var.alb_health_check_path
    matcher             = var.alb_health_check_matcher
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.name_prefix}-eks-tg"
  }
}

# listeners  
resource "aws_lb_listener" "this" {
  count = var.alb_enabled ? 1 : 0

  load_balancer_arn = aws_lb.load_balancer[0].arn
  port              = var.alb_listener_port
  protocol          = var.alb_listener_protocol
  ssl_policy        = var.alb_listener_protocol == "HTTPS" ? "ELBSecurityPolicy-TLS13-1-2-2021-06" : null
  certificate_arn   = var.alb_listener_protocol == "HTTPS" ? var.alb_certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_eks[0].arn
  }
}

# Route53 zones
resource "aws_route53_zone" "this" {
  count = var.create_route53_zone ? 1 : 0

  name = var.domain_name

  tags = {
    Name = var.domain_name
  }
}
# A name creation in route53
resource "aws_route53_record" "app" {
  count = var.alb_enabled && local.route53_zone_id != "" ? 1 : 0

  zone_id = local.route53_zone_id
  name    = var.app_hostname
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer[0].dns_name
    zone_id                = aws_lb.load_balancer[0].zone_id
    evaluate_target_health = true
  }
}

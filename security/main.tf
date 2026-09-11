locals {
  ssh_key_pair_name = var.ssh_key_name != "" ? var.ssh_key_name : "${var.name_prefix}-ssh-key"

  ssh_private_key_secret_name = var.ssh_private_key_secret_name != "" ? var.ssh_private_key_secret_name : "${var.name_prefix}-ssh-private-key"

  ec2_key_name = var.create_ssh_key ? local.ssh_key_pair_name : (var.bastion_key_name != "" ? var.bastion_key_name : null)
}

resource "aws_security_group" "bastion" {
  count = var.bastion_enabled ? 1 : 0

  name        = "${var.name_prefix}-bastion"
  description = "Bastion host in a public subnet"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-bastion"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  for_each = var.bastion_enabled ? toset(var.bastion_allowed_ssh_cidrs) : toset([])

  security_group_id = aws_security_group.bastion[0].id
  description       = "SSH"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  count = var.bastion_enabled ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# alb security group
resource "aws_security_group" "alb" {
  count = var.alb_enabled ? 1 : 0

  name        = "${var.name_prefix}-alb"
  description = "Internet-facing ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

# vpc security group ingree rules for http
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count = var.alb_enabled ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTP"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# ingress security group for https
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count = var.alb_enabled ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# alb all security group egress
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  count = var.alb_enabled ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# eks node security group
resource "aws_security_group" "eks_nodes" {
  name        = "${var.name_prefix}-eks-nodes"
  description = "Additional security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name                                            = "${var.name_prefix}-eks-nodes"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}

# security group ingress
resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Node to node"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# alb to nodes  security group ingress
resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  count = var.alb_enabled ? 1 : 0

  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "ALB to node target port"
  ip_protocol                  = "tcp"
  from_port                    = var.alb_target_port
  to_port                      = var.alb_target_port
  referenced_security_group_id = aws_security_group.alb[0].id
}

# node ssh rule from bastion
resource "aws_vpc_security_group_ingress_rule" "nodes_ssh_from_bastion" {
  count = var.bastion_enabled ? 1 : 0

  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "SSH from bastion"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion[0].id
}

# vpc egress from all nodes
resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  security_group_id = aws_security_group.eks_nodes.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# clickhouse security group
resource "aws_security_group" "clickhouse" {
  count = var.clickhouse_enabled ? 1 : 0

  name        = "${var.name_prefix}-clickhouse"
  description = "ClickHouse in a private subnet"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-clickhouse"
  }
}

# http traffic ingress security group
resource "aws_vpc_security_group_ingress_rule" "clickhouse_http_from_nodes" {
  count = var.clickhouse_enabled ? 1 : 0

  security_group_id            = aws_security_group.clickhouse[0].id
  description                  = "HTTP from EKS nodes"
  ip_protocol                  = "tcp"
  from_port                    = var.clickhouse_http_port
  to_port                      = var.clickhouse_http_port
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# clickhouse native  security ingress from clickhouse native node
resource "aws_vpc_security_group_ingress_rule" "clickhouse_native_from_nodes" {
  count = var.clickhouse_enabled ? 1 : 0

  security_group_id            = aws_security_group.clickhouse[0].id
  description                  = "Native TCP from EKS nodes"
  ip_protocol                  = "tcp"
  from_port                    = var.clickhouse_native_port
  to_port                      = var.clickhouse_native_port
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# clickhouse http from bastion
resource "aws_vpc_security_group_ingress_rule" "clickhouse_http_from_bastion" {
  count = var.clickhouse_enabled && var.bastion_enabled ? 1 : 0

  security_group_id            = aws_security_group.clickhouse[0].id
  description                  = "HTTP from bastion"
  ip_protocol                  = "tcp"
  from_port                    = var.clickhouse_http_port
  to_port                      = var.clickhouse_http_port
  referenced_security_group_id = aws_security_group.bastion[0].id
}

# ingress to clickhouse native from bastion
resource "aws_vpc_security_group_ingress_rule" "clickhouse_native_from_bastion" {
  count = var.clickhouse_enabled && var.bastion_enabled ? 1 : 0

  security_group_id            = aws_security_group.clickhouse[0].id
  description                  = "Native TCP from bastion"
  ip_protocol                  = "tcp"
  from_port                    = var.clickhouse_native_port
  to_port                      = var.clickhouse_native_port
  referenced_security_group_id = aws_security_group.bastion[0].id
}

# ingress for ssh from  bastion to clickhouse node
resource "aws_vpc_security_group_ingress_rule" "clickhouse_ssh_from_bastion" {
  count = var.clickhouse_enabled && var.bastion_enabled ? 1 : 0

  security_group_id            = aws_security_group.clickhouse[0].id
  description                  = "SSH from bastion"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion[0].id
}
# egress for security group - all traffic
resource "aws_vpc_security_group_egress_rule" "clickhouse_all" {
  count = var.clickhouse_enabled ? 1 : 0

  security_group_id = aws_security_group.clickhouse[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ec2 role
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
# iam role to ssm
resource "aws_iam_role" "ec2_ssm" {
  count = var.bastion_enabled || var.clickhouse_enabled ? 1 : 0

  name               = "${var.name_prefix}-ec2-ssm"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# policy attachment fo ssm 
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  count = var.bastion_enabled || var.clickhouse_enabled ? 1 : 0

  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  count = var.bastion_enabled || var.clickhouse_enabled ? 1 : 0

  name = "${var.name_prefix}-ec2-ssm"
  role = aws_iam_role.ec2_ssm[0].name
}

# EC2 creates the key pair in AWS (CreateKeyPair API). Private key PEM is stored in Secrets Manager.
resource "aws_secretsmanager_secret" "ssh_private_key" {
  count = var.create_ssh_key ? 1 : 0

  name                    = local.ssh_private_key_secret_name
  description             = "SSH private key (PEM) for ${var.name_prefix} bastion, ClickHouse, and EKS nodes"
  recovery_window_in_days = var.ssh_key_secret_recovery_window_days
}

resource "terraform_data" "ssh_keypair" {
  count = var.create_ssh_key ? 1 : 0

  triggers_replace = {
    key_name = local.ssh_key_pair_name
    region   = var.aws_region
  }

  provisioner "local-exec" {
    when        = create
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KEY_NAME   = local.ssh_key_pair_name
      REGION     = var.aws_region
      SECRET_ARN = aws_secretsmanager_secret.ssh_private_key[0].arn
    }
    command = <<-EOT
      set -euo pipefail
      if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" >/dev/null 2>&1; then
        if ! aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --region "$REGION" >/dev/null 2>&1; then
          echo "EC2 key pair $KEY_NAME exists but Secrets Manager secret has no value. Delete the key pair or recreate the secret." >&2
          exit 1
        fi
        exit 0
      fi
      MATERIAL=$(aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --key-type rsa \
        --key-format pem \
        --region "$REGION" \
        --query KeyMaterial \
        --output text)
      aws secretsmanager put-secret-value \
        --region "$REGION" \
        --secret-id "$SECRET_ARN" \
        --secret-string "$MATERIAL"
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KEY_NAME = self.triggers_replace.key_name
      REGION   = self.triggers_replace.region
    }
    command = <<-EOT
      set -euo pipefail
      aws ec2 delete-key-pair --key-name "$KEY_NAME" --region "$REGION" || true
    EOT
  }

  depends_on = [aws_secretsmanager_secret.ssh_private_key]
}

# IAM policy to attach to users/roles that may download the SSH private key.
resource "aws_iam_policy" "ssh_key_download" {
  count = var.create_ssh_key ? 1 : 0

  name        = "${var.name_prefix}-ssh-key-download"
  description = "Read SSH private key from Secrets Manager for ${var.name_prefix}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = aws_secretsmanager_secret.ssh_private_key[0].arn
      },
    ]
  })
}

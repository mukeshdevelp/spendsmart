data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


removed {
  from = terraform_data.ssh_keypair

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_secretsmanager_secret.ssh_private_key

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_iam_policy.ssh_key_download

  lifecycle {
    destroy = false
  }
}

resource "aws_iam_role" "ec2_ssm" {
  count = var.bastion_enabled ? 1 : 0

  name               = "${var.name_prefix}-ec2-ssm"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  count = var.bastion_enabled ? 1 : 0

  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = var.ec2_ssm_policy_arn
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  count = var.bastion_enabled ? 1 : 0

  name = "${var.name_prefix}-ec2-ssm"
  role = aws_iam_role.ec2_ssm[0].name
}

data "aws_key_pair" "selected" {
  key_name = var.ec2_key_name
}

data "aws_ssm_parameter" "bastion_ami" {
  count = var.bastion_enabled ? 1 : 0

  name = var.bastion_ami_ssm_parameter
}

resource "aws_instance" "bastion" {
  count = var.bastion_enabled ? 1 : 0

  ami           = data.aws_ssm_parameter.bastion_ami[0].value
  instance_type = var.bastion_instance_type
  subnet_id     = var.public_subnet_id
  vpc_security_group_ids = [
    aws_security_group.bastion[0].id
  ]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm[0].name
  associate_public_ip_address = true
  key_name                    = data.aws_key_pair.selected.key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size = var.bastion_root_volume_size
    volume_type = var.bastion_root_volume_type
    encrypted   = true
  }

  tags = {
    Name = "${var.name_prefix}-bastion"
    Role = "bastion"
  }
}

resource "aws_eip" "bastion" {
  count = var.bastion_enabled && var.bastion_associate_eip ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.bastion[0].id

  tags = {
    Name = "${var.name_prefix}-bastion-eip"
  }
}
# Bastion security group and rules are defined with the bastion host so the
# module owns all resources required to operate it.
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

  description = "SSH"
  ip_protocol = "tcp"
  from_port   = var.bastion_ssh_port
  to_port     = var.bastion_ssh_port

  cidr_ipv4 = each.value
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  for_each = var.bastion_enabled ? toset(var.bastion_egress_cidrs) : toset([])

  security_group_id = aws_security_group.bastion[0].id

  description = "Bastion egress"
  ip_protocol = "-1"

  cidr_ipv4 = each.value
}

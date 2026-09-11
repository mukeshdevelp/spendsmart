data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# bastion instance 
resource "aws_instance" "bastion" {
  count = var.bastion_enabled ? 1 : 0

  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_security_group_id]
  iam_instance_profile        = var.ec2_ssm_instance_profile_name
  associate_public_ip_address = true
  key_name                    = var.ec2_key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.name_prefix}-bastion"
    Role = "bastion"
  }
}

# Elastic IP for bastion
resource "aws_eip" "bastion" {
  count = var.bastion_enabled && var.bastion_associate_eip ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.bastion[0].id

  tags = {
    Name = "${var.name_prefix}-bastion-eip"
  }
}

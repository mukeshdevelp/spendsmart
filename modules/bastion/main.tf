# Bastion Security Group
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion"
  description = "Bastion host in a public subnet"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-bastion"
  }
}


# Bastion SSH Ingress
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  for_each = toset(var.bastion_allowed_ssh_cidrs)

  security_group_id = aws_security_group.bastion.id

  description = "SSH"
  ip_protocol = "tcp"

  from_port = var.bastion_ssh_port
  to_port   = var.bastion_ssh_port

  cidr_ipv4 = each.value
}

# Bastion Egress
resource "aws_vpc_security_group_egress_rule" "bastion_all" {


  security_group_id = aws_security_group.bastion.id

  description = "Bastion egress"
  ip_protocol = "-1"

  cidr_ipv4 = var.bastion_egress_cidrs
}

# Existing EC2 Key Pair
data "aws_key_pair" "selected" {
  key_name = var.ec2_key_name
}



# Amazon Linux AMI
#
# This uses SSM Parameter Store only to retrieve the AMI ID.
# It does NOT give the EC2 instance SSM access.

data "aws_ssm_parameter" "bastion_ami" {
  name = var.bastion_ami_ssm_parameter
}



# Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami           = data.aws_ssm_parameter.bastion_ami.value
  instance_type = var.bastion_instance_type

  subnet_id = var.public_subnet_id

  vpc_security_group_ids = [
    aws_security_group.bastion.id
  ]

  associate_public_ip_address = true

  # Existing EC2 key pair.
  # Used for normal SSH access.
  key_name = data.aws_key_pair.selected.key_name

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


# Bastion Elastic IP
resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = aws_instance.bastion.id

  tags = {
    Name = "${var.name_prefix}-bastion-eip"
  }
}






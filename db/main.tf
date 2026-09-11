data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# clickhouse instanceb 
resource "aws_instance" "clickhouse" {
  count = var.clickhouse_enabled ? 1 : 0

  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.clickhouse_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.clickhouse_security_group_id]
  iam_instance_profile   = var.ec2_ssm_instance_profile_name
  key_name               = var.ec2_key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size = var.clickhouse_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = var.clickhouse_data_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    mkfs -t xfs /dev/sdf || true
    mkdir -p /var/lib/clickhouse
    grep -q /var/lib/clickhouse /etc/fstab || echo "/dev/sdf /var/lib/clickhouse xfs defaults,nofail 0 2" >> /etc/fstab
    mount -a || true
  EOT

  tags = {
    Name = "${var.name_prefix}-clickhouse"
    Role = "ClickHouse"
  }
}

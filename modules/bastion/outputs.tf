output "bastion_security_group_id" {
  description = "Bastion security group ID."
  value       = var.bastion_enabled ? aws_security_group.bastion[0].id : null
}

output "clickhouse_security_group_id" {
  description = "ClickHouse security group ID."
  value       = var.clickhouse_enabled ? aws_security_group.clickhouse[0].id : null
}

output "ec2_key_name" {
  description = "EC2 key pair name for instances."
  value       = local.ec2_key_name
}

output "ssh_private_key_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the SSH private key PEM."
  value       = var.create_ssh_key ? aws_secretsmanager_secret.ssh_private_key[0].arn : null
}

output "ssh_private_key_secret_name" {
  description = "Secrets Manager secret name for the SSH private key."
  value       = var.create_ssh_key ? aws_secretsmanager_secret.ssh_private_key[0].name : null
}

output "ssh_key_download_policy_arn" {
  description = "IAM policy ARN granting GetSecretValue on the SSH private key secret."
  value       = var.create_ssh_key ? aws_iam_policy.ssh_key_download[0].arn : null
}

output "bastion_instance_id" {
  description = "Bastion EC2 instance ID."
  value       = var.bastion_enabled ? aws_instance.bastion[0].id : null
}

output "bastion_public_ip" {
  description = "Bastion public IP (Elastic IP when enabled)."
  value       = var.bastion_enabled ? (var.bastion_associate_eip ? aws_eip.bastion[0].public_ip : aws_instance.bastion[0].public_ip) : null
}

output "clickhouse_instance_id" {
  description = "ClickHouse EC2 instance ID."
  value       = var.clickhouse_enabled ? aws_instance.clickhouse[0].id : null
}

output "clickhouse_private_ip" {
  description = "ClickHouse private IP."
  value       = var.clickhouse_enabled ? aws_instance.clickhouse[0].private_ip : null
}

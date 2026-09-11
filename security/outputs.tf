output "bastion_security_group_id" {
  description = "Bastion security group ID."
  value       = var.bastion_enabled ? aws_security_group.bastion[0].id : null
}

output "alb_security_group_id" {
  description = "ALB security group ID."
  value       = var.alb_enabled ? aws_security_group.alb[0].id : null
}

output "eks_nodes_security_group_id" {
  description = "EKS nodes security group ID."
  value       = aws_security_group.eks_nodes.id
}

output "clickhouse_security_group_id" {
  description = "ClickHouse security group ID."
  value       = var.clickhouse_enabled ? aws_security_group.clickhouse[0].id : null
}

output "ec2_ssm_instance_profile_name" {
  description = "EC2 SSM instance profile name."
  value       = var.bastion_enabled || var.clickhouse_enabled ? aws_iam_instance_profile.ec2_ssm[0].name : null
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

output "ssh_keypair_ready" {
  description = "Sentinel indicating SSH key pair provisioning is complete."
  value       = var.create_ssh_key ? terraform_data.ssh_keypair[0].id : null
}

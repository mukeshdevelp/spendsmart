output "ec2_key_name" {
  description = "Validated, existing EC2 key pair name attached to the bastion and EKS worker nodes."
  value       = data.aws_key_pair.selected.key_name
}

output "bastion_instance_id" {
  description = "Bastion EC2 instance ID."
  value       = var.bastion_enabled ? aws_instance.bastion[0].id : null
}

output "bastion_public_ip" {
  description = "Bastion public IP (Elastic IP when enabled)."
  value       = var.bastion_enabled ? (var.bastion_associate_eip ? aws_eip.bastion[0].public_ip : aws_instance.bastion[0].public_ip) : null
}

output "bastion_security_group_id" {
  description = "Bastion security group ID."
  value       = var.bastion_enabled ? aws_security_group.bastion[0].id : null
}

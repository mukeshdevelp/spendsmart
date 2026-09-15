output "ec2_key_name" {
  description = "Validated, existing EC2 key pair name attached to the bastion and EKS worker nodes."

  value = data.aws_key_pair.selected.key_name
}


output "bastion_instance_id" {
  description = "Bastion EC2 instance ID."

  value = aws_instance.bastion.id
}


output "bastion_public_ip" {
  description = "Bastion Elastic IP."

  value = aws_eip.bastion.public_ip
}


output "bastion_security_group_id" {
  description = "Bastion security group ID."

  value = aws_security_group.bastion.id
}
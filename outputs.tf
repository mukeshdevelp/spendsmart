output "vpc_id" {
  description = "VPC ID."
  value       = module.network_skeleton.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = module.network_skeleton.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by availability zone."
  value       = module.network_skeleton.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by availability zone."
  value       = module.network_skeleton.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs keyed by availability zone."
  value       = module.network_skeleton.nat_gateway_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = module.network_skeleton.internet_gateway_id
}

output "bastion_instance_id" {
  description = "Bastion EC2 instance ID."
  value       = module.bastion.bastion_instance_id
}

output "bastion_security_group_id" {
  description = "Bastion security group ID."
  value       = module.bastion.bastion_security_group_id
}

output "ssh_key_pair_name" {
  description = "EC2 key pair name attached to bastion and EKS nodes."
  value       = module.bastion.ec2_key_name
}

output "bastion_public_ip" {
  description = "Bastion public IP (Elastic IP when enabled)."
  value       = module.bastion.bastion_public_ip
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint."
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.eks.eks_cluster_arn
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID attached to managed nodes."
  value       = module.eks.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "EKS nodes security group ID."
  value       = module.eks.eks_nodes_security_group_id
}

output "eks_node_group_names" {
  description = "Managed node group names."
  value       = module.eks.eks_node_group_names
}

output "eks_configure_kubectl" {
  description = "Command to update kubeconfig for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.eks_cluster_name}"
}

output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.eks.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN."
  value       = module.eks.alb_arn
}

output "alb_target_group_arn" {
  description = "Target group ARN in front of EKS."
  value       = module.eks.alb_target_group_arn
}

output "bucket_name" {
  description = "Shared S3 bucket."
  value       = module.s3.bucket_name
}

output "data_location" {
  description = "S3 URI for Glue / data-lake objects."
  value       = module.s3.data_location
}

output "athena_output_location" {
  description = "S3 URI for Athena query results."
  value       = module.s3.athena_output_location
}

output "glue_database_name" {
  description = "Glue Data Catalog database name."
  value       = module.glue.glue_database_name
}

output "glue_role_arn" {
  description = "IAM role ARN for Glue jobs and crawlers."
  value       = module.glue.glue_role_arn
}

output "athena_workgroup_name" {
  description = "Athena workgroup name."
  value       = module.athena.athena_workgroup_name
}

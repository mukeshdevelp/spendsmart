# OP - vpc id
output "vpc_id" {
  description = "VPC ID."
  value       = module.network_skeleton.vpc_id
}

# OP - cidr of vpc
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

output "nodes_nacl_id" {
  description = "Network ACL ID associated with the private/node subnets."
  value       = module.network_skeleton.nodes_nacl_id
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

output "ssh_key_pair_name" {
  description = "EC2 key pair name attached to bastion, ClickHouse, and EKS nodes."
  value       = module.bastion.ec2_key_name
}

output "ssh_private_key_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the SSH private key PEM."
  value       = module.bastion.ssh_private_key_secret_arn
}

output "ssh_private_key_secret_name" {
  description = "Secrets Manager secret name for the SSH private key."
  value       = module.bastion.ssh_private_key_secret_name
}

output "ssh_key_download_policy_arn" {
  description = "IAM policy ARN granting GetSecretValue on the SSH private key secret."
  value       = module.bastion.ssh_key_download_policy_arn
}

output "ssh_private_key_download_command" {
  description = "AWS CLI command to save the private key locally (requires ssh_key_download policy)."
  value       = var.create_ssh_key ? "aws secretsmanager get-secret-value --region ${var.aws_region} --secret-id ${module.bastion.ssh_private_key_secret_name} --query SecretString --output text > ${local.name_prefix}-ssh.pem && chmod 400 ${local.name_prefix}-ssh.pem" : null
}

output "bastion_public_ip" {
  description = "Bastion public IP (Elastic IP when enabled)."
  value       = module.bastion.bastion_public_ip
}

output "clickhouse_instance_id" {
  description = "ClickHouse EC2 instance ID."
  value       = module.bastion.clickhouse_instance_id
}

output "clickhouse_private_ip" {
  description = "ClickHouse private IP."
  value       = module.bastion.clickhouse_private_ip
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

output "eks_node_group_names" {
  description = "Managed node group names."
  value       = module.eks.eks_node_group_names
}

output "eks_configure_kubectl" {
  description = "Command to update kubeconfig for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.eks_cluster_name}"
}

output "alb_dns_name" {
  description = "ALB DNS name. Point Route 53 or clients at this hostname."
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

output "route53_zone_id" {
  description = "Route 53 hosted zone ID."
  value       = module.eks.route53_zone_id
}

output "route53_name_servers" {
  description = "Name servers for a zone created by this stack."
  value       = module.eks.route53_name_servers
}

output "app_fqdn" {
  description = "Application DNS name aliased to the ALB."
  value       = module.eks.app_fqdn
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

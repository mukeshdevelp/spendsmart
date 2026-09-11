# OP - vpc id
output "vpc_id" {
  description = "VPC ID."
  value       = module.networking.vpc_id
}

# OP - cidr of vpc
output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = module.networking.vpc_cidr
}
# OP - public subnets ids
output "public_subnet_ids" {
  description = "Public subnet IDs keyed by availability zone."
  value       = module.networking.public_subnet_ids
}
# OP - private subnet ids
output "private_subnet_ids" {
  description = "Private subnet IDs keyed by availability zone."
  value       = module.networking.private_subnet_ids
}
# OP - nacl id
output "nodes_nacl_id" {
  description = "Network ACL ID associated with the private/node subnets."
  value       = module.networking.nodes_nacl_id
}
# Nat gateway id
output "nat_gateway_ids" {
  description = "NAT gateway IDs keyed by availability zone."
  value       = module.networking.nat_gateway_ids
}
# OP - Internet gateway id
output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = module.networking.internet_gateway_id
}

# OP - bastion instance id
output "bastion_instance_id" {
  description = "Bastion EC2 instance ID."
  value       = module.ec2.bastion_instance_id
}
# OP - EC2 key pair name for SSH
output "ssh_key_pair_name" {
  description = "EC2 key pair name attached to bastion, ClickHouse, and EKS nodes."
  value       = module.security.ec2_key_name
}

# OP - Secrets Manager secret for SSH private key
output "ssh_private_key_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the SSH private key PEM."
  value       = module.security.ssh_private_key_secret_arn
}

output "ssh_private_key_secret_name" {
  description = "Secrets Manager secret name for the SSH private key."
  value       = module.security.ssh_private_key_secret_name
}

# IAM policy ARN — attach to IAM users/roles allowed to download the key
output "ssh_key_download_policy_arn" {
  description = "IAM policy ARN granting GetSecretValue on the SSH private key secret."
  value       = module.security.ssh_key_download_policy_arn
}

# Download the key and use for SSH
output "ssh_private_key_download_command" {
  description = "AWS CLI command to save the private key locally (requires ssh_key_download policy)."
  value       = var.create_ssh_key ? "aws secretsmanager get-secret-value --region ${var.aws_region} --secret-id ${module.security.ssh_private_key_secret_name} --query SecretString --output text > ${local.name_prefix}-ssh.pem && chmod 400 ${local.name_prefix}-ssh.pem" : null
}

# OP - bastion public IP
output "bastion_public_ip" {
  description = "Bastion public IP (Elastic IP when enabled)."
  value       = module.ec2.bastion_public_ip
}

# OP - clickhouse node id
output "clickhouse_instance_id" {
  description = "ClickHouse EC2 instance ID."
  value       = module.db.clickhouse_instance_id
}
# OP - clickhouse Private IP for configure
output "clickhouse_private_ip" {
  description = "ClickHouse private IP."
  value       = module.db.clickhouse_private_ip
}
# OP - eks cluster name
output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.eks_cluster_name
}

# OP - cluster endpoint
output "eks_cluster_endpoint" {
  description = "EKS API endpoint."
  value       = module.eks.eks_cluster_endpoint
}

# OP - cluster ARN
output "eks_cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.eks.eks_cluster_arn
}
# OP - cluster security group id
output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID attached to managed nodes."
  value       = module.eks.eks_cluster_security_group_id
}

# All node group names
output "eks_node_group_names" {
  description = "Managed node group names."
  value       = module.eks.eks_node_group_names
}
# Command to update kubeconfig
output "eks_configure_kubectl" {
  description = "Command to update kubeconfig for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.eks_cluster_name}"
}

# OP - ALB DNS name
output "alb_dns_name" {
  description = "ALB DNS name. Point Route 53 or clients at this hostname."
  value       = module.eks.alb_dns_name
}
# OP - ALB arn
output "alb_arn" {
  description = "ALB ARN."
  value       = module.eks.alb_arn
}

# ALB target groups
output "alb_target_group_arn" {
  description = "Target group ARN in front of EKS. Register NodePort/pod targets or attach node ASGs after the cluster is running."
  value       = module.eks.alb_target_group_arn
}

# Route53 zone id
output "route53_zone_id" {
  description = "Route 53 hosted zone ID."
  value       = module.eks.route53_zone_id
}
# Route53 name servers
output "route53_name_servers" {
  description = "Name servers for a zone created by this stack. Delegate the parent domain to these."
  value       = module.eks.route53_name_servers
}

# Application DNS Aliased to ALB
output "app_fqdn" {
  description = "Application DNS name aliased to the ALB."
  value       = module.eks.app_fqdn
}
# Data bucket
output "data_bucket_name" {
  description = "S3 data-lake bucket."
  value       = module.glue.data_bucket_name
}
# athena bucket result name
output "athena_results_bucket_name" {
  description = "S3 bucket for Athena query results."
  value       = module.athena.athena_results_bucket_name
}
# Glue  database output name
output "glue_database_name" {
  description = "Glue Data Catalog database name."
  value       = module.glue.glue_database_name
}

# OP - role for aws glue arn
output "glue_role_arn" {
  description = "IAM role ARN for Glue jobs and crawlers."
  value       = module.glue.glue_role_arn
}
# OP - Athena workgroup name
output "athena_workgroup_name" {
  description = "Athena workgroup name."
  value       = module.athena.athena_workgroup_name
}

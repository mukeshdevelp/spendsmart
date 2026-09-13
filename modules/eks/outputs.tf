output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "eks_node_group_names" {
  description = "Managed node group names."
  value       = [for ng in aws_eks_node_group.this : ng.node_group_name]
}

output "alb_security_group_id" {
  description = "ALB security group ID."
  value       = var.alb_enabled ? aws_security_group.alb[0].id : null
}

output "eks_nodes_security_group_id" {
  description = "EKS nodes security group ID."
  value       = aws_security_group.eks_nodes.id
}

output "alb_dns_name" {
  description = "ALB DNS name."
  value       = var.alb_enabled ? aws_lb.load_balancer[0].dns_name : null
}

output "alb_arn" {
  description = "ALB ARN."
  value       = var.alb_enabled ? aws_lb.load_balancer[0].arn : null
}

output "alb_target_group_arn" {
  description = "ALB target group ARN."
  value       = var.alb_enabled ? aws_lb_target_group.target_group_eks[0].arn : null
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID."
  value       = local.route53_zone_id != "" ? local.route53_zone_id : null
}

output "route53_name_servers" {
  description = "Name servers for a zone created by this module."
  value       = var.create_route53_zone ? aws_route53_zone.this[0].name_servers : null
}

output "app_fqdn" {
  description = "Application DNS name aliased to the ALB."
  value       = var.alb_enabled && local.route53_zone_id != "" ? aws_route53_record.app[0].fqdn : null
}

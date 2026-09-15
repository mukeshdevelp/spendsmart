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
  value = aws_security_group.alb.id
}

output "eks_nodes_security_group_id" {
  description = "EKS nodes security group ID."
  value       = aws_security_group.eks_nodes.id
}

output "alb_dns_name" {
  value = aws_lb.load_balancer.dns_name
}
output "alb_arn" {
  value = aws_lb.load_balancer.arn
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.target_group_eks.arn
}
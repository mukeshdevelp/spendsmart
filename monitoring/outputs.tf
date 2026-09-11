output "eks_log_group_name" {
  description = "CloudWatch log group name for EKS cluster."
  value       = aws_cloudwatch_log_group.eks.name
}

output "eks_log_group_arn" {
  description = "CloudWatch log group ARN for EKS cluster."
  value       = aws_cloudwatch_log_group.eks.arn
}

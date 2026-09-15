output "role_name" {
  description = "IAM role name for spendsmart analytics, cost, AWS infrastructure and service metadata access"
  value       = aws_iam_role.analytics.name
}

output "role_arn" {
  description = "IAM role ARN for spendsmart analytics, cost, AWS infrastructure and service metadata access"
  value       = aws_iam_role.analytics.arn
}

output "policy_name" {
  description = "IAM policy name for spendsmart analytics, cost, AWS infrastructure and service metadata access"
  value       = aws_iam_policy.analytics.name
}

output "policy_arn" {
  description = "IAM policy ARN for spendsmart analytics, cost, AWS infrastructure and service metadata access"
  value       = aws_iam_policy.analytics.arn
}
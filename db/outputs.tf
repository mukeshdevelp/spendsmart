output "clickhouse_instance_id" {
  description = "ClickHouse EC2 instance ID."
  value       = var.clickhouse_enabled ? aws_instance.clickhouse[0].id : null
}

output "clickhouse_private_ip" {
  description = "ClickHouse private IP."
  value       = var.clickhouse_enabled ? aws_instance.clickhouse[0].private_ip : null
}

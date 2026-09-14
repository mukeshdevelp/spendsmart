# athena workgroup creation
resource "aws_athena_workgroup" "this" {
  name = var.athena_workgroup_name

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    bytes_scanned_cutoff_per_query = var.athena_bytes_scanned_cutoff > 0 ? var.athena_bytes_scanned_cutoff : null

    result_configuration {
      output_location = var.athena_output_location

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

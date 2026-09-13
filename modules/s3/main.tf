# Bucket is created once by bootstrap; main stack references it and manages prefix-specific rules.
data "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = data.aws_s3_bucket.this.id

  rule {
    id     = "expire-athena-results"
    status = "Enabled"

    filter {
      prefix = "${var.athena_results_prefix}/"
    }

    expiration {
      days = 30
    }
  }
}

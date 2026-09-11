# local define - to define bucket name a dynamo table name
locals {
  state_bucket_name = var.state_bucket_name != "" ? var.state_bucket_name : "${var.project_name}-tfstate"
  lock_table_name   = var.dynamodb_table_name != "" ? var.dynamodb_table_name : "${var.project_name}-tfstate-locks"
}

# bootstraping the aws bucket for storing remote backend
resource "aws_s3_bucket" "remote_backend" {
  bucket        = local.state_bucket_name
  force_destroy = false
}

# S3 bucket to create store the remote backend version
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.remote_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# encrpting server side data by default
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.remote_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# blocking public access to the bucket
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.remote_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# dynamo db for state locking
resource "aws_dynamodb_table" "state_lock" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

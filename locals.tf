# getting current account id for IAM module
data "aws_caller_identity" "current" {
  # no code is required here, it would just return the account id
}
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # S3 bucket names are globally unique. The account ID makes the default
  # name unique while allowing callers to provide an explicit name instead.
  bucket_name = var.bucket_name != "" ? var.bucket_name : "${local.name_prefix}-${data.aws_caller_identity.current.account_id}"
  # for IAM module
  iam_trusted_principal_identifiers = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

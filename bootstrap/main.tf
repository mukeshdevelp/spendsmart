# One-time stack: creates the shared S3 bucket + DynamoDB remote backend.
# Uses LOCAL state (no backend.tf here). Run once, then use the root stack for everything else.

module "bootstrap" {
  source = "../modules/bootstrap"

  project_name        = var.project_name
  environment         = var.environment
  bucket_name         = var.bucket_name
  dynamodb_table_name = var.dynamodb_table_name
}

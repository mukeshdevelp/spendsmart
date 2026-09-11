# aws region for bucket
aws_region = "us-east-1"

# project name
project_name = "spendsmart"

# bucket state name - not given fallback to conditional statement
state_bucket_name = ""

# dynamo table name - not given fallback to conditional statement
dynamodb_table_name = ""


# generalized tags to used with all resource
tags = {
  Project   = "spendsmart"
  ManagedBy = "terraform"
  Component = "tfstate-backend"
}

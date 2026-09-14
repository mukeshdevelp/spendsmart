# Glue catalog database
resource "aws_glue_catalog_database" "this" {
  name        = var.glue_database_name
  description = "SpendSmart analytics catalog"
}

# iam policy document for glue
data "aws_iam_policy_document" "glue_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

# glue iam role creation
resource "aws_iam_role" "glue" {
  name               = "${var.name_prefix}-glue"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
}

# glue role attachment
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# fetching glue policy
data "aws_iam_policy_document" "glue_s3" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      var.bucket_arn,
      "${var.bucket_arn}/${var.data_prefix}",
      "${var.bucket_arn}/${var.data_prefix}/*",
    ]
  }
}

# aws iam policy for glue
resource "aws_iam_role_policy" "glue_s3" {
  name   = "${var.name_prefix}-glue-s3"
  role   = aws_iam_role.glue.id
  policy = data.aws_iam_policy_document.glue_s3.json
}

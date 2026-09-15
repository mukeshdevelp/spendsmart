#  policy fetching
data "aws_iam_policy_document" "analytics" {

  statement {
    sid    = "STSValidation"
    effect = "Allow"

    actions = [
      "sts:GetCallerIdentity",
      "sts:AssumeRole"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AthenaGlueAndCUR"
    effect = "Allow"

    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryResultsStream",
      "athena:ListDatabases",
      "athena:ListTableMetadata",
      "athena:GetWorkGroup",
      "athena:ListWorkGroups",

      "glue:GetTable",
      "glue:GetTables",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",

      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetBucketLocation",
      "s3:HeadBucket"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CostExplorer"
    effect = "Allow"

    actions = [
      "ce:GetCostAndUsage",
      "ce:GetCostForecast",
      "ce:GetDimensionValues",
      "ce:GetTags"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "S3Metadata"
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketLifecycleConfiguration",
      "s3:GetPublicAccessBlock"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "EC2AndNetworkMetadata"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNatGateways",
      "ec2:DescribeRouteTables",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeAddresses",
      "ec2:DescribeFlowLogs",
      "ec2:DescribeRegions",
      "ec2:DescribeImages",

      "cloudwatch:GetMetricData"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ELBMetadata"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeInstanceHealth"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "WAFMetadata"
    effect = "Allow"

    actions = [
      "wafv2:GetWebACLForResource",
      "wafv2:ListWebACLs"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "RDSMetadata"
    effect = "Allow"

    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBClusters",
      "rds:DescribeDBSnapshots",
      "rds:ListTagsForResource",
      "rds:DescribeDBSubnetGroups"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ECSMetadata"
    effect = "Allow"

    actions = [
      "ecs:ListClusters",
      "ecs:DescribeClusters",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ecs:ListServices",
      "ecs:DescribeServices"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ECRMetadata"
    effect = "Allow"

    actions = [
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
      "ecr:GetLifecyclePolicy"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "EKSMetadata"
    effect = "Allow"

    actions = [
      "eks:ListClusters",
      "eks:DescribeCluster",
      "eks:ListNodegroups",
      "eks:DescribeNodegroup",
      "eks:ListAddons",
      "eks:DescribeAddon",
      "eks:ListFargateProfiles",
      "eks:DescribeFargateProfile"
    ]

    resources = ["*"]
  }
}

# attach policy to role
data "aws_iam_policy_document" "assume_role" {

  statement {
    sid    = "AllowTrustedPrincipal"
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = var.trusted_principal_type
      identifiers = var.trusted_principal_identifiers
    }
  }
}


resource "aws_iam_role" "analytics" {
  name = "${var.project_name}-${var.environment}${var.iam_role_name_suffix}"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}${var.iam_role_name_suffix}"
    }
  )
}


resource "aws_iam_policy" "analytics" {
  name        = "${var.project_name}-${var.environment}${var.iam_policy_name_suffix}"
  description = "Analytics, cost, AWS infrastructure and service metadata access"

  policy = data.aws_iam_policy_document.analytics.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}${var.iam_policy_name_suffix}"
    }
  )
}


resource "aws_iam_role_policy_attachment" "analytics" {
  role       = aws_iam_role.analytics.name
  policy_arn = aws_iam_policy.analytics.arn
}
data "aws_iam_policy_document" "frontend-static-s3" {
  count = var.gh_action_roles ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.cloudfront.static-bucket}/*",
      module.cloudfront.static-bucket
    ]
  }
}

data "aws_iam_policy_document" "backend-static-s3" {
  count = var.gh_action_roles ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      module.cloudfront.django-static-bucket,
      "${module.cloudfront.django-static-bucket}/*",
    ]
  }
}

data "aws_iam_policy_document" "glue-scripts-s3" {
  count = var.gh_action_roles ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      format("%s/*", module.s3.bucket_arn["glue-scripts"]),
      module.s3.bucket_arn["glue-scripts"]
    ]
  }
}

data "aws_iam_policy_document" "backend-read-ecs-logs" {
  count = var.gh_action_roles ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "logs:GetLogEvents"
    ]
    resources = [
      format("%s:log-stream:*", aws_cloudwatch_log_group.migration_fargate_task.arn),
    ]
  }
}

data "aws_iam_policy_document" "allow-distribution-invalidation" {
  count = var.gh_action_roles ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "cloudfront:GetInvalidation",
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      module.cloudfront.distribution_arn
    ]
  }
}

data "aws_iam_policy_document" "get-tag-resources" {
  count = var.gh_action_roles ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "tag:GetResources",
    ]
    resources = [
      "*"
    ]
  }
}

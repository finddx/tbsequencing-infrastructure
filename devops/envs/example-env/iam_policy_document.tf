data "aws_iam_policy_document" "ec2_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "fargate_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "lambda_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "rds_access" {
  statement {
    actions = [
      "rds-db:connect"
    ]
    resources = ["arn:aws:rds-db:${local.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.db_default.db_instance_resource_id}/${local.db_iam_user_name}"]
  }
}

data "aws_iam_policy_document" "fargate-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}


# Splitting actions between fargate execution (aka launching the ECS task)
# and fargate task (aka what Django needs to run)
data "aws_iam_policy_document" "fargate_execution" {
  # Accessing the Docker repository for getting the image
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = [
      module.ecr.ecr_arns["backend"]
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = [
      "*"
    ]
  }
  # Writting the logs to Cloudwatch
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${resource.aws_cloudwatch_log_group.backend_fargate_task.arn}:*",
      "${resource.aws_cloudwatch_log_group.migration_fargate_task.arn}:*",
    ]
  }
  # The Django and ADFS secrets are read at the task definition
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      resource.aws_secretsmanager_secret.adfs.arn,
      resource.aws_secretsmanager_secret.django.arn,
    ]
  }
}

# What Django does
data "aws_iam_policy_document" "fargate_task" {
  # /!\ Django also writes directly some logs into Cloudwatch /!\
  # The task creates specific log groups for some activities
  # And it needs the Action because it will try to create the group
  # even if it already exists... And it must put logs there too.
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${resource.aws_cloudwatch_log_group.django-delegate.arn}:*",
      "${resource.aws_cloudwatch_log_group.django-admin.arn}:*",
      "${resource.aws_cloudwatch_log_group.django-server.arn}:*",
    ]
  }
  # The NCBI API key is sometimes read by the migration task
  # To download the reference genome at setting up for instance
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      resource.aws_secretsmanager_secret.ncbi_entrez.arn,
    ]
  }
  # Django sends emails
  statement {
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values = [
        var.no_reply_email
      ]
    }
  }
  # Actually not sure about those...
  statement {
    effect = "Allow"
    actions = [
      "ses:GetSendStatistics",
      "ses:GetSendQuota"
    ]
    resources = [
      "*"
    ]
  }
  # Finally Django copies files into S3 (when user uploads fastq/excel)
  # and also tags them
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions"
    ]
    resources = [
      module.s3.bucket_arn["backend-sequence-data"],
      module.s3.bucket_arn["backend-media"],
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      "${module.s3.bucket_arn["backend-sequence-data"]}/*",
      "${module.s3.bucket_arn["backend-media"]}/*"
    ]
  }

}

data "aws_iam_policy_document" "step_function_executions" {
  statement {
    effect = "Allow"
    actions = [
      "states:ListExecutions",
      "states:ListMapRuns",
      "states:ListStateMachines",
      "states:StartExecution",
      "states:StartExecution",
      "states:StopExecution",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "glue_executions" {
  statement {
    effect = "Allow"
    actions = [
      "glue:ListCrawlers",
      "glue:ListCrawls",
      "glue:ListJobs",
      "glue:ListSchemas",
      "glue:GetJob",
      "glue:GetJobBookmark",
      "glue:GetJobRun",
      "glue:GetCrawlers",
      "glue:GetCrawler",
      "glue:GetCrawlerMetrics",
      "glue:StartCrawler",
      "glue:StartJobRun",
      "glue:StopCrawler",
      "glue:ResetJobBookmark"
    ]
    resources = [
      "*"
    ]
  }
}

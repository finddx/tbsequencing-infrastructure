locals {
  project_name        = var.project_name
  environment         = var.environment
  bucket_name         = "tf-backend-${local.project_name}-${local.environment}"
  dynamodb_table_name = "tf-backend-lock-${local.project_name}-${local.environment}"
  tags = {
    project     = local.project_name
    terraformed = "true"
  }
}
resource "aws_s3_bucket" "default" {
  bucket_prefix = local.bucket_name
  lifecycle {
    #    prevent_destroy = true
  }
  tags = merge(
    local.tags,
    {
      "Description" = "Terraform State bucket"
    }
  )
}

resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "default" {
  bucket = aws_s3_bucket.default.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_s3_bucket_acl" "default" {
  depends_on = [
    aws_s3_bucket_ownership_controls.default,
  ]
  bucket = aws_s3_bucket.default.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "default" {
  name         = local.dynamodb_table_name
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  server_side_encryption {
    enabled = false
  }

  point_in_time_recovery {
    enabled = false
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    local.tags,
    {
      "Description" = "Terraform State Lock table"
    }
  )
}

output "Description" {
  value = "Check bellow aws_account_* are equal!"
}

data "aws_caller_identity" "current" {}

output "aws_account_current" {
  description = "check into which AWS account you just have deployed a state bucket and a dynamodb table"
  value       = data.aws_caller_identity.current.account_id
}

output "dynamodb_table" {
  value = local.dynamodb_table_name
}

output "bucket" {
  value = local.bucket_name
}

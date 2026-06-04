terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  backend_bucket_name   = var.bucket_name
  dynamodb_table_name   = var.dynamodb_table_name
  backend_resource_tags = merge(var.common_tags, { Name = "${var.project_name}-terraform-backend" })
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.backend_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.backend_resource_tags
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.backend_resource_tags
}

output "backend_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "The AWS S3 bucket name used for Terraform remote state."
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The DynamoDB table name used for Terraform state locking."
}

############################################
# CloudWatch Log Groups
############################################

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name_prefix        = "/aws/vpc/flowlogs/${var.project_name}-"
  retention_in_days  = var.log_retention_days

  kms_key_arn = aws_kms_key.cloudwatch_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc-flow-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name_prefix        = "/aws/app/${var.project_name}-"
  retention_in_days  = var.log_retention_days

  kms_key_arn = aws_kms_key.cloudwatch_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-app-logs"
    }
  )
}

############################################
# KMS Key for CloudWatch Logs
############################################

resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM policies"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-cloudwatch-logs-key"
    }
  )
}

resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/${var.project_name}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

############################################
# CloudWatch Alarms
############################################

resource "aws_cloudwatch_metric_alarm" "vpc_flow_logs_errors" {
  count = var.enable_advanced_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-vpc-flow-logs-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedLogDelivery"
  namespace           = "AWS/VPC"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when VPC Flow Logs delivery fails"
  treat_missing_data  = "notBreaching"

  tags = local.common_tags
}

############################################
# CloudWatch Dashboard
############################################

resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_advanced_monitoring ? 1 : 0

  dashboard_name = "${var.project_name}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/VPC", "FailedLogDelivery", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "VPC Flow Logs Status"
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message | stats count() by @message"
          region  = var.aws_region
          title   = "Recent Log Patterns"
        }
      }
    ]
  })
}

############################################
# CloudTrail for API Auditing
############################################

resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_logs]
  kms_key_id                    = aws_kms_key.cloudtrail.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-trail"
    }
  )
}

############################################
# S3 Bucket for CloudTrail Logs
############################################

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket_prefix = "${var.project_name}-cloudtrail-"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-cloudtrail-logs"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kmaster_key_id    = aws_kms_key.cloudtrail.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

############################################
# KMS Key for CloudTrail
############################################

resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for CloudTrail encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM policies"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to use the key"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:DecryptDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-cloudtrail-key"
    }
  )
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/${var.project_name}-cloudtrail"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

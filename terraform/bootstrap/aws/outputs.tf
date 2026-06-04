output "backend_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the Terraform remote state S3 bucket."
}

output "backend_bucket_region" {
  value       = var.aws_region
  description = "The AWS region for remote state.
"}

output "terraform_lock_table" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The DynamoDB table name used for state locking."
}

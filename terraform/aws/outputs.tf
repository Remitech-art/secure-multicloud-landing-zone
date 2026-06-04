output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "The CIDR block of the VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of private subnet IDs"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.main.id
  description = "The ID of the Internet Gateway"
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.main[*].id
  description = "List of NAT Gateway IDs"
}

output "nat_gateway_eips" {
  value       = aws_eip.nat[*].public_ip
  description = "List of NAT Gateway Elastic IPs"
}

output "bastion_security_group_id" {
  value       = aws_security_group.bastion.id
  description = "The ID of the bastion security group"
}

output "app_security_group_id" {
  value       = aws_security_group.app.id
  description = "The ID of the application security group"
}

output "bastion_iam_role_arn" {
  value       = aws_iam_role.bastion.arn
  description = "ARN of the bastion IAM role"
}

output "app_iam_role_arn" {
  value       = aws_iam_role.app.arn
  description = "ARN of the application IAM role"
}

output "logs_bucket_id" {
  value       = aws_s3_bucket.logs.id
  description = "The ID of the logs S3 bucket"
}

output "logs_bucket_arn" {
  value       = aws_s3_bucket.logs.arn
  description = "The ARN of the logs S3 bucket"
}

output "vpc_flow_logs_group_name" {
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
  description = "Name of the VPC Flow Logs CloudWatch Log Group"
}

output "app_logs_group_name" {
  value       = aws_cloudwatch_log_group.app_logs.name
  description = "Name of the application CloudWatch Log Group"
}

output "cloudtrail_logs_bucket_id" {
  value       = aws_s3_bucket.cloudtrail_logs.id
  description = "The ID of the CloudTrail logs S3 bucket"
}

output "cloudtrail_trail_name" {
  value       = aws_cloudtrail.main.name
  description = "Name of the CloudTrail trail"
}

output "vpn_gateway_id" {
  value       = var.enable_vpn ? aws_vpn_gateway.main[0].id : null
  description = "The ID of the VPN Gateway (if enabled)"
}

output "kms_s3_key_id" {
  value       = aws_kms_key.s3.key_id
  description = "The ID of the KMS key used for S3 encryption"
}

output "kms_cloudwatch_logs_key_id" {
  value       = aws_kms_key.cloudwatch_logs.key_id
  description = "The ID of the KMS key used for CloudWatch Logs encryption"
}

output "kms_cloudtrail_key_id" {
  value       = aws_kms_key.cloudtrail.key_id
  description = "The ID of the KMS key used for CloudTrail encryption"
}

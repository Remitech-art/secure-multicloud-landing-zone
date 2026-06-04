variable "aws_region" {
  description = "AWS region for the bootstrap backend resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for backend resource naming."
  type        = string
  default     = "secure-multicloud"
}

variable "bucket_name" {
  description = "Name of the S3 bucket used for Terraform remote state."
  type        = string
  default     = "secure-multicloud-terraform-state"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for Terraform remote state locking."
  type        = string
  default     = "secure-multicloud-terraform-locks"
}

variable "common_tags" {
  description = "Common tags for backend resources."
  type        = map(string)
  default = {
    Team       = "Platform-Engineering"
    CostCenter = "Engineering"
  }
}

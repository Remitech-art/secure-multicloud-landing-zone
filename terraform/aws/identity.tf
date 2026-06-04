variable "github_organization" {
  description = "GitHub organization or user for GitHub Actions OIDC trust."
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository name for GitHub Actions OIDC trust."
  type        = string
  default     = ""
}

variable "github_oidc_audience" {
  description = "OIDC audience used by GitHub Actions when requesting tokens."
  type        = string
  default     = "sts.amazonaws.com"
}

locals {
  github_oidc_subject = trimspace(var.github_organization) != "" && trimspace(var.github_repository) != "" ? "repo:${var.github_organization}/${var.github_repository}:*" : ""
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = local.github_oidc_subject != "" ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = [var.github_oidc_audience]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  count       = local.github_oidc_subject != "" ? 1 : 0
  name_prefix = "${var.project_name}-github-actions-"
  description = "Role trusted by GitHub Actions via OIDC for secure deployment workflows."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.github_oidc_subject
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-github-actions-role"
    }
  )
}


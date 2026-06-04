variable "github_organization" {
  description = "GitHub organization or user for GitHub Actions workload identity."
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository name for GitHub Actions workload identity."
  type        = string
  default     = ""
}

locals {
  github_repository_subject = trimspace(var.github_organization) != "" && trimspace(var.github_repository) != "" ? "${var.github_organization}/${var.github_repository}" : ""
}

resource "google_iam_workload_identity_pool" "github_actions" {
  count                    = local.github_repository_subject != "" ? 1 : 0
  provider                 = google
  project                  = var.project_id
  workload_identity_pool_id = "github-actions-pool"
  display_name             = "GitHub Actions Workload Identity Pool"
  description              = "OIDC trust pool for GitHub Actions deployments."
}

resource "google_iam_workload_identity_pool_provider" "github_actions" {
  count                    = local.github_repository_subject != "" ? 1 : 0
  provider                 = google
  workload_identity_pool_id = google_iam_workload_identity_pool.github_actions[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider"
  display_name             = "GitHub Actions OIDC Provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"    = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }
}

resource "google_service_account_iam_member" "github_actions_workload_identity" {
  count = local.github_repository_subject != "" ? 1 : 0

  service_account_id = google_service_account.platform.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions[0].name}/attribute.repository/${local.github_repository_subject}"
}

output "gcp_workload_identity_pool_name" {
  value       = google_iam_workload_identity_pool.github_actions[0].name
  description = "The name of the GCP workload identity pool for GitHub Actions."
}

output "gcp_workload_identity_provider_name" {
  value       = google_iam_workload_identity_pool_provider.github_actions[0].name
  description = "The name of the GCP workload identity pool provider for GitHub Actions."
}

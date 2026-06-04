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

locals {
  github_oidc_subject = trimspace(var.github_organization) != "" && trimspace(var.github_repository) != "" ? "repo:${var.github_organization}/${var.github_repository}:*" : ""
}

resource "azuread_application_federated_identity_credential" "github_actions" {
  count               = local.github_oidc_subject != "" ? 1 : 0
  application_object_id = azuread_application.landing_zone.object_id
  name                = "${var.project_name}-github-actions-federated-identity"
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = local.github_oidc_subject
  audiences           = ["api://AzureADTokenExchange"]
}

output "azure_github_actions_federated_identity_subject" {
  value       = local.github_oidc_subject
  description = "The GitHub Actions OIDC subject used for Azure federated identity."
}

# Identity and Access Management

This document captures the production identity wiring for the multi-cloud landing zone.

## Goals

- Avoid static credentials in CI/CD and deployment workflows.
- Use provider-native federated identity trust for GitHub Actions.
- Scope deployment identities to repository-level access and backend-specific resources.
- Separate bootstrap resources from production deployment workloads.

## AWS

The repository now provides an AWS GitHub Actions OIDC trust builder in `terraform/aws/identity.tf`.

- Creates an `aws_iam_openid_connect_provider` for `https://token.actions.githubusercontent.com`
- Creates a dedicated IAM role that can be assumed by GitHub Actions
- Restricts the subject to `repo:<org>/<repo>:*`

Production guidance:

- Set `github_organization` and `github_repository` in AWS variable configuration.
- Attach least-privilege policies to the OIDC role after bootstrap.
- Use the bootstrap bucket and DynamoDB lock table before running the main AWS landing zone.

## Azure

Azure identity wiring is now available in `terraform/azure/identity.tf`.

- Creates an Azure AD application and service principal for the landing zone
- Adds an Azure AD federated identity credential for GitHub Actions OIDC
- Restricts identity issuance to the configured GitHub repository subject

Production guidance:

- Configure `github_organization` and `github_repository` variables in Azure.
- Review the federated identity credential and use Azure environment protection on GitHub deployments.
- Keep role assignments scoped to the resource group or subscription as required.

## GCP

GCP workload identity is now wired in `terraform/gcp/identity.tf`.

- Creates a workload identity pool and provider for GitHub Actions
- Maps GitHub OIDC assertions to GCP identity attributes
- Binds the platform service account to workloads from the configured repository

Production guidance:

- Set GitHub repo variables and verify the workload identity pool provider in the GCP console.
- Use `roles/iam.workloadIdentityUser` only for the platform service account.
- Harden service account IAM bindings with least privilege and remove unused service account keys.

## State and Access Separation

- Backend bootstrap is intentionally separate from the main landing zone deployment.
- Bootstrap resources create remote state infrastructure only.
- Main cloud deployments use the pre-created backends to avoid self-dependency issues.

## GitHub Deployment Governance

- Use GitHub protected environments for production deployments.
- Enforce approvals and required checks before production workflow deployment.
- Do not store cloud credentials directly in repository secrets when OIDC is available.

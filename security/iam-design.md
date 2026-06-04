# IAM Design

## Objectives

- Enforce least privilege across cloud resources.
- Separate identity from privileges with role-based access.
- Use service accounts for automation and machine identity.
- Define clear project, folder, and organization boundaries.

## Key Principles

- Centralize identity management where possible.
- Use groups for human access, not individual identities.
- Prefer predefined roles for common functions and custom roles for specialized workloads.
- Enforce MFA and strong authentication for administrative access.

## Recommended Pattern

- `org-admins` group for organization-wide administration.
- `security-ops` group for security tooling and monitoring.
- `platform-service-account` for Terraform and deployment automation.
- `workload-service-accounts` scoped to each application cluster.

## GCP Specifics

- Assign `roles/viewer` and `roles/iam.securityReviewer` for auditors.
- Use `roles/iam.serviceAccountUser` only where workload identity must impersonate service accounts.
- Manage service account keys through short-lived credentials and Workload Identity where possible.

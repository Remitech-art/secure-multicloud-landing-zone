# Least Privilege Model

## Purpose

The least-privilege model limits permissions to only what is required for a user or service to perform its job. This reduces blast radius and makes it easier to audit access.

## Implementation Steps

- Inventory permissions for each role and service account.
- Map tasks to specific roles rather than granting broad access.
- Use managed roles first, then custom roles for specific needs.
- Review and revoke unused permissions regularly.

## Cloud Example Patterns

- Infrastructure provisioning uses a scoped Terraform service account.
- Kubernetes controllers use dedicated RBAC bindings for cluster operations.
- Monitoring and logging services are granted only write-level access.
- Security tooling has separate accounts with `securitycenter` and alerting permissions.

## Validation

- Use IAM dry-run or policy analyzer tools.
- Audit bindings against approved role lists.
- Monitor privileged role assignment changes.

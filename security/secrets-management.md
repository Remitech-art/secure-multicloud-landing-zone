# Secrets Management (Production Standard)

This guidance describes recommended secrets handling for each cloud provider in production.

AWS
- Use AWS Secrets Manager for application secrets and credentials.
- Encrypt secrets with a Customer Managed KMS key (CMK).
- Rotate secrets regularly and grant access via IAM roles with least privilege.

Azure
- Use Azure Key Vault for secrets and certificates.
- Use access policies or RBAC and Managed Identities to grant fine-grained access.
- Enable purge protection and soft-delete for Key Vaults.

GCP
- Use Secret Manager for secret storage.
- Enable CMEK for Secret Manager if required.
- Grant access via IAM (principals) and avoid embedding secrets in code/config.

Rotation & Access
- Automate rotation where supported; define rotation windows and audit rotation events.
- Use short-lived credentials where possible (STS, Workload Identity Federation, Managed Identities).
- Audit access via CloudTrail / Activity Logs / Audit Logs.
# Secrets Management

## Principles

- Never store secrets in source control.
- Use managed secrets stores for keys, tokens, and credentials.
- Enforce least privilege access through role-based policies.
- Automate rotation and auditing for all secrets.

## Enterprise Strategy

- Centralize secrets in cloud-native vault services:
  - AWS Secrets Manager
  - Azure Key Vault
  - GCP Secret Manager
- Use dedicated service identities and role bindings for secret access.
- Avoid static credentials and long-lived service account keys.

## Secret Storage Standards

- Store secrets only in managed secret stores.
- Encrypt secrets at rest with provider-managed or customer-managed keys.
- Use versioned secrets and keep audit logs of all access.
- Apply immutable access policies and protect secrets with access reviews.

## Rotation Policy

- Rotate application credentials at least every 90 days.
- Rotate service account keys or managed identity credentials on a defined schedule.
- Automate rotation for database credentials, API keys, and TLS certificates.
- Ensure automated consumers refresh secrets without application restarts when possible.

## Access Control Model

- Use dedicated secret access roles:
  - `secrets-reader` for runtime applications
  - `secrets-admin` for ops and automation
- Assign access by group or workload identity, not by individual username.
- Audit every secret retrieval and deny all access by default.
- Use conditional access and network restrictions where supported.

## Cloud-Specific Controls

### AWS
- Store secrets in AWS Secrets Manager.
- Protect secrets with AWS KMS keys.
- Use IAM policies scoped to a specific secret or secret path.
- Enable automatic rotation for supported secret types.

### Azure
- Store secrets in Azure Key Vault.
- Use soft-delete and purge-protection.
- Configure Key Vault access policies or RBAC with least privilege.
- Enable logging for Key Vault operations.

### GCP
- Store secrets in GCP Secret Manager.
- Use IAM policies scoped to individual secrets.
- Enable secret versioning.
- Grant access via service account impersonation.

## Operational Best Practices

- Monitor failed access attempts and unusual secret usage.
- Use centralized logging for secrets access events.
- Maintain artifact and environment separation for production secrets.
- Periodically review and remove unused secrets.

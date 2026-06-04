# Secrets Management

## Principles

- Never store secrets in source control.
- Use managed secrets stores for keys, tokens, and credentials.
- Rotate secrets frequently and automatically where possible.

## Recommended Approach

- Use native secret services such as Google Secret Manager, Azure Key Vault, and AWS Secrets Manager.
- Grant access to secrets with least privilege and audit every secret retrieval.
- Protect pipeline secrets with encrypted build variables and service identities.

## Use Cases

- Application database credentials.
- API keys for external services.
- TLS certificates and encryption keys.

## Best Practices

- Enforce secret versioning and secure deletion policies.
- Monitor access patterns for suspicious retrieval activity.
- Use ephemeral credentials for automation where feasible.

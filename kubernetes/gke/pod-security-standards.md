# GKE Pod Security Standards

## Recommended Pod Hardening

- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- `allowPrivilegeEscalation: false`
- `seccompProfile.type: RuntimeDefault`
- Drop all unnecessary Linux capabilities

## Example SecurityContext

```yaml
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
      - ALL
```

## Enforcement

- Use GKE Pod Security Admission for `baseline` or `restricted` profiles.
- Apply namespace-level policies for production workloads.
- Combine with Binary Authorization and image scanning.

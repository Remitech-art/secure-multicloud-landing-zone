# AKS Pod Security Standards

## Recommended Controls

- Enforce `runAsNonRoot` and `readOnlyRootFilesystem`.
- Disable privilege escalation.
- Use `seccompProfile.type: RuntimeDefault`.
- Drop unnecessary capabilities.

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

## AKS Enforcement

- Use Azure Policy and Pod Security Admission.
- Protect namespaces with network policies and identity-based access.
- Configure Azure AD workload identities for pod authentication.

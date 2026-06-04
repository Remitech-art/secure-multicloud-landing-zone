# EKS Pod Security Standards

## Recommended settings

- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- `allowPrivilegeEscalation: false`
- `seccompProfile` set to `RuntimeDefault`
- `capabilities.drop: ["ALL"]`

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

## EKS Enforcement

- Use AWS EKS Pod Security Admission or OPA Gatekeeper.
- Validate policy compliance at deployment time.
- Isolate workloads into namespaces with dedicated network controls.

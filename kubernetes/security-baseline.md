# Kubernetes Security Baseline

## RBAC

- Define least-privilege roles for applications, operators, and administrators.
- Use service accounts with scoped permissions.
- Avoid cluster-admin bindings for workloads.
- Apply Role and RoleBinding objects per namespace.

## Network Policies

- Use `NetworkPolicy` to limit pod-to-pod communication.
- Default deny all ingress and egress, then explicitly allow required traffic.
- Segment namespaces for application tiers and platform services.

## Pod Security Standards

- Enforce `runAsNonRoot` and `readOnlyRootFilesystem`.
- Set `allowPrivilegeEscalation: false`.
- Use `seccompProfile.type: RuntimeDefault`.
- Drop all unnecessary Linux capabilities.

## Secure Ingress

- Terminate TLS at ingress with managed certificates.
- Use WAF or cloud-native ingress security features.
- Require HTTPS and redirect HTTP traffic.
- Restrict ingress access to trusted domains or IP ranges.

## Secrets Handling

- Store secrets in cloud-native secret stores, not in manifests.
- Use Kubernetes `Secret` objects only for non-sensitive configuration with encryption at rest enabled.
- Prefer external secret operators for runtime secret injection.
- Rotate secrets regularly and audit secret access.

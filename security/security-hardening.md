# Security Hardening

## Principles

- Adopt deny-by-default architecture for network and IAM controls.
- Enforce least privilege for all identities and service accounts.
- Harden network controls by default and open only required paths.
- Ensure auditability through logs and policy enforcement.

## Terraform Security Hardening

- Use dedicated service accounts for each cloud provider and workload.
- Avoid broad roles such as `Owner`, `Contributor`, or `roles/editor`.
- Use conditional access policies and fine-grained role assignments.
- Restrict firewall rules to specific sources and destinations.

## Network Hardening

- AWS: replace open SSH rules with managed access, SSM, or bastion-specific IP allowlists.
- Azure: apply NSGs to subnet boundaries and minimize inbound traffic.
- GCP: use VPC firewall rules with limited CIDR ranges and deny-by-default rules.
- Kubernetes: enforce network policies that allow only required pod-to-pod traffic.

## Identity Hardening

- Use IAM role assumption and workload identity instead of static credentials.
- Enable MFA for administrative users and require strong authentication.
- Rotate service account keys and secrets according to policy.
- Audit IAM changes and use policy analyzer tools.

## Logging and Alerting

- Ensure all security groups and firewall changes are tracked.
- Capture audit logs for IAM, network, and resource changes.
- Integrate cloud security event feeds into monitoring and SOC workflows.

## Compliance

- Map security controls to standards such as CIS, NIST, and ISO.
- Use automated checks to enforce baseline configurations.
- Document deviations and compensating controls.

# Encryption Strategy

## Goals

- Protect data at rest and in transit.
- Use cloud-native encryption services and key management.
- Minimize exposure of raw keys.

## At Rest

- Use managed encryption for storage buckets, databases, and disks.
- Enable customer-managed encryption keys (CMEK) for sensitive workloads.
- Protect secrets with cloud KMS or secrets management solutions.

## In Transit

- Require TLS for all application and API traffic.
- Use HTTPS for ingress and service mesh communication.
- Encrypt service-to-service traffic inside clusters where possible.

## Key Management

- Store keys in a centralized, audited KMS.
- Enforce key rotation policies.
- Grant access to key operations only to authorized service accounts.

## Monitoring

- Log access to encryption keys and key lifecycle events.
- Alert on unexpected key policy changes.

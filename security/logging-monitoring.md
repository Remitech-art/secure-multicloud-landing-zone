# Logging and Monitoring

## Objectives

- Capture security events and operational telemetry.
- Ensure logs cannot be tampered with by application owners.
- Provide visibility for incident response and compliance.

## Platform Logging

- Enable audit logs for IAM, Admin, Data Access, and System Events.
- Route logs to a centralized storage bucket or logging workspace.
- Use immutable retention for security-critical logs.

## Monitoring

- Deploy baseline alerting for unauthorized access, policy changes, and configuration drift.
- Monitor identity activity, service account usage, and network anomalies.
- Integrate with Cloud Monitoring and Security Command Center.

## Recommended Controls

- Use log sinks with unique writer identities.
- Send alerts to a SOC or security operations channel.
- Build dashboards for anomalous access patterns and compliance status.

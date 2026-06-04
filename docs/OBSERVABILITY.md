# Observability

## Overview

Production systems require unified observability across infrastructure, applications, and security events.

## AWS Observability

- Use CloudWatch for metrics, logs, and alarms.
- Send application and infrastructure logs to CloudWatch Logs.
- Implement CloudWatch Dashboards for service health and security signals.
- Use CloudWatch Alarms for availability, performance, and anomalous behavior.

## Azure Observability

- Use Azure Monitor for metrics, logs, and alerts.
- Centralize logs in Log Analytics workspaces.
- Use Application Insights for application telemetry.
- Implement Azure Monitor alerts for critical events.

## GCP Observability

- Use Cloud Monitoring for metrics, uptime checks, and dashboards.
- Use Cloud Logging for centralized log ingestion.
- Configure alerts for security incidents, resource saturation, and failures.

## Kubernetes Observability

- Deploy Prometheus for cluster and workload metrics.
- Use Grafana dashboards for service-level visibility.
- Export application and pod metrics to Prometheus.
- Integrate cluster logs with the cloud provider logging backend.

## Monitoring Architecture

- Collect infrastructure metrics via provider-native services.
- Collect Kubernetes metrics via Prometheus and kube-state-metrics.
- Use Grafana for unified dashboards and alerts.
- Correlate logs, metrics, and traces in a centralized observability platform.

# FinOps Strategy

## Tagging Strategy

- Apply consistent tags across all clouds:
  - `Environment`
  - `Project`
  - `Owner`
  - `CostCenter`
  - `Service`
  - `Lifecycle`
- Enforce tag presence through Terraform validation and policy checks.
- Map tags to billing categories in AWS Cost Explorer, Azure Cost Management, and GCP Billing.

## Budget Alerts

### AWS
- Configure AWS Budgets for forecasted monthly spend.
- Alert on threshold breaches at 50%, 75%, and 90%.
- Tie notifications to PagerDuty or Slack.

### Azure
- Use Azure Cost Management budgets for subscriptions and resource groups.
- Set alerts for actual and forecasted overspend.
- Attach action groups for email and webhook notifications.

### GCP
- Create budgets and alerts for projects, labels, and services.
- Use exported budget reports to BigQuery for analysis.
- Trigger alerts on 70%, 85%, and 95% thresholds.

## Lifecycle Policies

- Implement lifecycle policies for storage and logging:
  - AWS S3 lifecycle rules for archive and delete
  - Azure Blob lifecycle management for cooler tiers
  - GCP Storage lifecycle rules for Nearline and Coldline
- Apply retention and transition rules for audit logs.

## Reserved Capacity Strategy

- Evaluate savings plans for AWS compute and EC2 instance usage.
- Use Azure Reserved VM Instances or Savings Plans for steady-state workloads.
- Use GCP Committed Use Discounts for predictable resource use.
- Review reserved capacity quarterly and adjust based on utilization.

## Cost Optimization Recommendations

- Rightsize compute resources using cloud monitoring insights.
- Prefer managed platform services over self-managed infrastructure where appropriate.
- Use spot/preemptible instances for non-critical workloads.
- Remove orphaned disks, volumes, and unused IP addresses.
- Use autoscaling to reduce idle capacity.

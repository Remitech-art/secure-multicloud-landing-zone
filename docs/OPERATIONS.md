# Operations Guide

## Overview

This guide provides operational procedures for managing and maintaining the Secure Multi-Cloud Landing Zone infrastructure.

---

## Daily Operations

### Health Checks

#### AWS
```bash
# Check VPC status
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,State]'

# Check NAT Gateway status
aws ec2 describe-nat-gateways \
  --query 'NatGateways[*].[NatGatewayId,State]'

# Check security group rules
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*secure-multicloud*" \
  --query 'SecurityGroups[*].[GroupId,GroupName,IpPermissions]'

# Monitor CloudWatch alarms
aws cloudwatch describe-alarms --state-value ALARM
```

#### Azure
```bash
# Check resource group status
az group show --name secure-multicloud-prod-rg

# Check VNET status
az network vnet show \
  --resource-group secure-multicloud-prod-rg \
  --name secure-multicloud-vnet

# Check NSG rules
az network nsg rule list \
  --resource-group secure-multicloud-prod-rg \
  --nsg-name secure-multicloud-public-nsg

# Monitor alerts
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/secure-multicloud-prod-rg
```

### Log Review

#### AWS CloudWatch Logs
```bash
# View VPC Flow Logs
aws logs tail /aws/vpc/flowlogs/secure-multicloud --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/vpc/flowlogs/secure-multicloud \
  --filter-pattern "REJECT"

# Retrieve CloudTrail logs
aws cloudtrail lookup-events \
  --max-results 50 \
  --lookup-attributes AttributeKey=EventName,AttributeValue=PutObject
```

#### Azure Log Analytics
```bash
# Query logs via Azure CLI
az monitor log-analytics query \
  --workspace secure-multicloud-law \
  --analytics-query "
    AzureDiagnostics
    | where Category == 'NetworkSecurityGroupFlowLogEvent'
    | where Action == 'D'
    | summarize count() by Resource
  "

# View recent activity logs
az monitor activity-log list --resource-group secure-multicloud-prod-rg
```

---

## Weekly Maintenance

### Infrastructure Validation

```bash
# AWS: Run Terraform validation
cd terraform/aws
terraform validate
terraform plan -lock=false

# Azure: Run Terraform validation
cd terraform/azure
terraform validate
terraform plan -lock=false
```

### Security Group / NSG Audit

```bash
# AWS: Review ingress rules
aws ec2 describe-security-groups \
  --query 'SecurityGroups[?IpPermissions[*].[IpRanges[0].CidrIp]!={[`0.0.0.0/0`]}]' | grep -E "0.0.0.0/0"

# Azure: Review NSG rules
az network nsg rule list \
  --resource-group secure-multicloud-prod-rg \
  --nsg-name secure-multicloud-public-nsg \
  --query "[?sourceAddressPrefix=='*']"
```

### Backup Verification

```bash
# AWS: Verify S3 versioning
aws s3api get-bucket-versioning \
  --bucket $(terraform output -raw logs_bucket_id)

# Azure: Verify storage soft delete
az storage account show \
  --resource-group secure-multicloud-prod-rg \
  --name <storage-account-name> \
  --query "properties.softDeletePolicy"
```

---

## Monthly Tasks

### Access Review

#### AWS IAM Review
```bash
# List all IAM users
aws iam list-users

# Review role assignments
aws iam list-role-tags --role-name secure-multicloud-bastion-*

# Check for unused keys
aws iam get-credential-report

# Review key age
aws iam list-access-keys --user-name <username>
```

#### Azure RBAC Review
```bash
# List role assignments
az role assignment list --resource-group secure-multicloud-prod-rg

# Review service principals
az ad sp list --display-name "*secure-multicloud*"

# Check managed identities
az identity list --resource-group secure-multicloud-prod-rg
```

### Credential Rotation

#### AWS Access Keys
```bash
# Create new access key
aws iam create-access-key --user-name <username>

# Delete old key after migration
aws iam delete-access-key --user-name <username> --access-key-id <old-key-id>
```

#### AWS Console Password
```bash
# Force password change on next login
aws iam update-login-profile --user-name <username> --password <new-password>
```

#### Azure Credentials
```bash
# Rotate service principal password
az ad sp credential reset --id <app-id>

# Update secrets in Key Vault
az keyvault secret set \
  --vault-name secure-multicloud-kv \
  --name app-password \
  --value <new-password>
```

### Patch Management

```bash
# Check for available updates (Terraform)
cd terraform/aws
terraform init -upgrade

# Review changelog for provider updates
grep "hashicorp/aws" .terraform.lock.hcl

# Validate no breaking changes
terraform plan

# Apply updates
terraform init -upgrade
terraform validate
terraform apply
```

---

## Quarterly Tasks

### Disaster Recovery Testing

#### AWS
```bash
# Backup key infrastructure details
terraform output -json > backup-$(date +%Y%m%d).json

# Test state recovery
terraform plan -out=test.tfplan
# Verify plan matches expected state

# Test failover procedures (documented in DISASTER_RECOVERY.md)
```

#### Azure
```bash
# Export resource group configuration
az group export --resource-group secure-multicloud-prod-rg > rg-backup.json

# Verify backup completeness
jq '.resources | length' rg-backup.json

# Test recovery plan (documented in DISASTER_RECOVERY.md)
```

### Security Audit

#### Automated Scanning
```bash
# Run Terraform security scanning
cd terraform

# Using tfsec
tfsec aws/ azure/

# Using checkov
checkov -d terraform/
```

#### Manual Security Review Checklist
- [ ] Verify S3 bucket public access is blocked
- [ ] Confirm KMS key rotation is enabled
- [ ] Check IAM policies follow least privilege
- [ ] Review NSG rules for overly permissive ranges
- [ ] Verify encryption is enabled on all applicable resources
- [ ] Confirm logging is enabled and retention is appropriate
- [ ] Audit access logs for suspicious activity

### Cost Optimization Review

```bash
# AWS Cost Analysis
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost"

# Azure Cost Analysis
az costmanagement query --type "Usage" \
  --timeframe "MonthToDate" \
  --dataset granularity=Daily aggregation=totalCost
```

---

## Incident Response Procedures

### Network Connectivity Issue

#### Investigation
```bash
# AWS: Check route tables
aws ec2 describe-route-tables \
  --filters Name=vpc-id,Values=$VPC_ID

# AWS: Test connectivity
aws ec2-instance-connect send-ssh-public-key \
  --instance-id <instance-id> \
  --os-user ec2-user \
  --ssh-public-key.OpenSSHPublicKey "file:///path/to/key.pub"

# Azure: Check NSG rules
az network nsg rule show \
  --resource-group secure-multicloud-prod-rg \
  --nsg-name secure-multicloud-public-nsg \
  --name <rule-name>

# Azure: Test connectivity
az network nic ip-config show \
  --resource-group secure-multicloud-prod-rg \
  --nic-name <nic-name>
```

#### Resolution
```bash
# AWS: Update security group
aws ec2 authorize-security-group-ingress \
  --group-id <sg-id> \
  --protocol tcp --port 443 \
  --cidr 10.0.0.0/16

# Azure: Update NSG rule
az network nsg rule update \
  --resource-group secure-multicloud-prod-rg \
  --nsg-name secure-multicloud-public-nsg \
  --name <rule-name> \
  --priority 100
```

### High Latency / Performance Degradation

#### Investigation
```bash
# AWS: Check VPC Flow Logs for dropped packets
aws logs filter-log-events \
  --log-group-name /aws/vpc/flowlogs/secure-multicloud \
  --filter-pattern "REJECT" | jq '.events | length'

# AWS: Monitor NAT Gateway metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/NatGateway \
  --metric-name BytesOutToDestination \
  --statistics Sum

# Azure: Check NSG flow logs
az network watcher flow-log show \
  --resource-group secure-multicloud-prod-rg

# Azure: Review Application Insights performance
az monitor app-insights component show \
  --app secure-multicloud-appinsights
```

#### Resolution
```bash
# AWS: Increase NAT Gateway capacity
# Typically transparent, but can add additional NAT Gateways

# Azure: Scale up Application Service Plan
az appservice plan update \
  --resource-group secure-multicloud-prod-rg \
  --name <plan-name> \
  --sku P2V2
```

### Unauthorized Access Attempt

#### Investigation
```bash
# AWS: Query CloudTrail for failed auth
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=Unauthorized \
  --max-results 50

# AWS: Check for unauthorized IAM changes
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=PutUserPolicy

# Azure: Query Activity Logs
az monitor activity-log list \
  --resource-group secure-multicloud-prod-rg \
  --filters "eventTimestamp gt $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)"
```

#### Response
```bash
# AWS: Disable IAM user immediately
aws iam update-user --user-name <compromised-user> --no-cli-pager

# AWS: Invalidate all sessions
aws iam delete-user-policy --user-name <compromised-user> --policy-name *

# Azure: Disable service principal
az ad app delete --id <app-id>

# Notify security team and begin forensics
```

---

## Monitoring Setup

### AWS CloudWatch Dashboard

```bash
# Create custom dashboard
aws cloudwatch put-dashboard \
  --dashboard-name secure-multicloud-ops \
  --dashboard-body file://dashboard.json
```

### Azure Monitor Alerts

```bash
# Create action group for notifications
az monitor action-group create \
  --resource-group secure-multicloud-prod-rg \
  --name SecureMultiCloud-Alerts

# Add email notification
az monitor action-group email-receiver add \
  --resource-group secure-multicloud-prod-rg \
  --action-group-name SecureMultiCloud-Alerts \
  --name ops-team \
  --email-receiver ops@example.com
```

---

## Documentation

### Change Log Template

```markdown
## Change Log

### Date: YYYY-MM-DD
- **Change**: Description
- **Component**: AWS/Azure
- **Reason**: Business justification
- **Risk**: Low/Medium/High
- **Approved By**: Name
- **Implemented By**: Name
- **Status**: Completed/In Progress
```

### Runbook Template

```markdown
## Runbook: [Procedure Name]

### Objective
[What this runbook accomplishes]

### Prerequisites
[Required access, tools, knowledge]

### Steps
1. Step 1
2. Step 2
3. ...

### Rollback
[How to undo changes if necessary]

### Monitoring
[What to watch after completion]

### Escalation
[Who to contact if issues occur]
```

---

## Training & Knowledge Transfer

### Key Competencies Required
- Terraform and Infrastructure as Code
- AWS VPC and networking concepts
- Azure networking and security
- Security and compliance principles
- CI/CD pipeline operations

### Resources
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)

---

## Contacts & Escalation

### On-Call Schedule
- Primary: [Name]
- Secondary: [Name]
- Manager: [Name]

### Escalation Path
1. On-call engineer
2. Engineering manager
3. Security team
4. VP of Engineering
5. CTO

### External Support
- AWS: https://console.aws.amazon.com/support/
- Azure: https://portal.azure.com/
- Terraform: https://www.terraform.io/support.html

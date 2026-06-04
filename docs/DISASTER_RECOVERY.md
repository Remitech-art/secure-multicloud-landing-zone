# Disaster Recovery Plan

## Executive Summary

This document outlines the Disaster Recovery (DR) strategy for the Secure Multi-Cloud Landing Zone. It defines Recovery Point Objectives (RPO), Recovery Time Objectives (RTO), and procedures for infrastructure recovery across AWS and Azure.

---

## Recovery Objectives

### Recovery Point Objective (RPO)
- **AWS**: < 1 hour (via S3 versioning and snapshots)
- **Azure**: < 1 hour (via blob versioning and point-in-time recovery)
- **State Files**: < 15 minutes (via version control and S3/Azure backend)

### Recovery Time Objective (RTO)
- **AWS**: 4 hours (full VPC recreation, security configurations)
- **Azure**: 4 hours (full VNET recreation, security configurations)
- **Combined**: 8 hours (both clouds operational)

### Recovery Service Level Objectives (SLOs)
- **Availability**: 99.5% (52 minutes downtime/month max)
- **Data Integrity**: 100% (no data loss)
- **Service Restoration**: Priority-based (critical → non-critical)

---

## Disaster Scenarios & Recovery Procedures

### Scenario 1: AWS Region Failure

#### Detection
- AWS health dashboard reports regional outage
- CloudWatch alarms fail to receive metrics
- All API calls to region fail with region-specific errors
- Estimated detection time: < 5 minutes

#### Impact Assessment
- All AWS resources unavailable (VPC, security groups, S3, KMS, CloudWatch)
- Applications unable to process
- DNS may still resolve but connections fail

#### Recovery Steps

**Phase 1: Preparation (0-30 minutes)**
```bash
# 1. Activate secondary region (us-west-2) deployment
cd terraform/aws
cp terraform.tfvars terraform.tfvars.primary-backup
sed -i 's/aws_region = "us-east-1"/aws_region = "us-west-2"/' terraform.tfvars

# 2. Retrieve latest state from backup
aws s3 cp s3://your-terraform-state-bucket/aws/landing-zone/terraform.tfstate . \
  --region us-west-2

# 3. Update backend configuration
sed -i 's/us-east-1/us-west-2/' provider.tf
```

**Phase 2: Infrastructure Rebuild (30-120 minutes)**
```bash
# 1. Initialize Terraform in new region
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan deployment
terraform plan -out=tfplan.recovery

# 4. Apply configuration
terraform apply tfplan.recovery

# 5. Verify outputs
terraform output
```

**Phase 3: Data Recovery (120-180 minutes)**
```bash
# 1. Restore S3 data from cross-region replication
aws s3 sync s3://your-logs-bucket \
  s3://your-logs-bucket-us-west-2 \
  --region us-west-2

# 2. Recover CloudTrail logs
aws cloudtrail create-trail \
  --name secure-multicloud-trail-recovery \
  --s3-bucket-name your-logs-bucket-us-west-2

# 3. Validate data integrity
aws s3api head-object \
  --bucket your-logs-bucket-us-west-2 \
  --key critical-file
```

**Phase 4: Validation (180-240 minutes)**
```bash
# 1. Test connectivity
aws ec2 describe-vpcs --region us-west-2
aws ec2 describe-security-groups --region us-west-2

# 2. Verify security posture
terraform plan -lock=false
# Should show no changes

# 3. Application health checks
curl https://app.example.com/health

# 4. Log verification
aws logs describe-log-groups --region us-west-2
```

---

### Scenario 2: Azure Region Failure

#### Detection
- Azure status page reports regional outage
- Monitor alerts stop triggering
- Portal access regional resources fails
- Estimated detection time: < 5 minutes

#### Impact Assessment
- All Azure resources unavailable (VNET, NSGs, Storage, Key Vault)
- Applications unable to process
- Multi-region replication prevents data loss but requires failover

#### Recovery Steps

**Phase 1: Preparation (0-30 minutes)**
```bash
# 1. Activate secondary region (westus2)
cd terraform/azure
cp terraform.tfvars terraform.tfvars.primary-backup
sed -i 's/azure_region = "eastus"/azure_region = "westus2"/' terraform.tfvars

# 2. Retrieve latest state
az storage blob download \
  --account-name tfstate \
  --container-name tfstate \
  --name azure/landing-zone/terraform.tfstate \
  --file terraform.tfstate

# 3. Update backend config
sed -i 's/eastus/westus2/' provider.tf
```

**Phase 2: Infrastructure Rebuild (30-120 minutes)**
```bash
# 1. Initialize Terraform in new region
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan deployment
terraform plan -out=tfplan.recovery

# 4. Apply configuration
terraform apply tfplan.recovery

# 5. Verify outputs
terraform output
```

**Phase 3: Data Recovery (120-180 minutes)**
```bash
# 1. Restore storage account data
az storage copy \
  --source https://sourceaccount.blob.core.windows.net/logs \
  --destination-account-name destaccount \
  --destination-container logs

# 2. Recover Log Analytics data
az monitor log-analytics workspace data-export create \
  --workspace-name secure-multicloud-law-recovery \
  --export-name DataExport001

# 3. Validate data integrity
az storage blob list \
  --account-name destaccount \
  --container-name logs
```

**Phase 4: Validation (180-240 minutes)**
```bash
# 1. Test connectivity
az network vnet list --resource-group secure-multicloud-prod-rg

# 2. Verify security posture
terraform plan -lock=false

# 3. Application health checks
curl https://app.example.com/health

# 4. Monitor validation
az monitor metrics list-definitions \
  --resource /subscriptions/{sub-id}/resourceGroups/secure-multicloud-prod-rg
```

---

### Scenario 3: Data Loss / Ransomware Attack

#### Detection
- Unusual file deletion patterns in logs
- S3/Blob object deletion alerts
- Application data corruption errors
- Estimated detection time: < 30 minutes

#### Impact Assessment
- Current data inaccessible or corrupted
- Previous versions available via versioning/soft delete
- Backup data may be safe in separate account

#### Recovery Steps

**Phase 1: Isolation (Immediate)**
```bash
# AWS: Block all public write access
aws s3api put-bucket-policy --bucket logs-bucket \
  --policy file://deny-delete-policy.json

# Azure: Block storage writes
az storage account update \
  --resource-group secure-multicloud-prod-rg \
  --name logstorage \
  --https-only true \
  --min-tls-version TLS1_2
```

**Phase 2: Investigation (0-60 minutes)**
```bash
# AWS: Review CloudTrail logs for DeleteObject calls
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteObject \
  --max-results 100

# Azure: Review Activity Logs
az monitor activity-log list \
  --resource-group secure-multicloud-prod-rg \
  --filter "eventTimestamp ge $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)"
```

**Phase 3: Recovery (60-180 minutes)**
```bash
# AWS: Restore from S3 version history
aws s3api list-object-versions \
  --bucket logs-bucket \
  --prefix critical-data

# Restore specific version
aws s3api get-object \
  --bucket logs-bucket \
  --key critical-data.json \
  --version-id <version-id> \
  critical-data.recovered.json

# Azure: Restore from blob snapshots
az storage blob snapshot list \
  --account-name logstorage \
  --container-name logs

# Copy snapshot to new blob
az storage blob copy start \
  --source-uri https://logstorage.blob.core.windows.net/logs/file?snapshot=2024-01-01 \
  --destination-blob file.recovered.json
```

**Phase 4: Validation & Forensics (180-240 minutes)**
```bash
# Verify data integrity
md5sum critical-data.recovered.json

# Compare with backup
diff critical-data.json critical-data.recovered.json

# Preserve forensics
tar czf forensics-$(date +%Y%m%d).tar.gz \
  terraform.tfstate terraform.tfstate.backup logs/ \
  activity-logs/

# Generate incident report
```

---

### Scenario 4: Compromised Infrastructure (Security Breach)

#### Detection
- GuardDuty detects unauthorized API calls
- Suspicious network traffic in VPC Flow Logs
- Unauthorized IAM role assumption
- Estimated detection time: < 15 minutes (with monitoring)

#### Impact Assessment
- Infrastructure potentially compromised
- Credentials may be exposed
- Data may have been exfiltrated
- Compliance incident trigger

#### Recovery Steps

**Phase 1: Containment (Immediate)**
```bash
# AWS: Disable all IAM user keys
aws iam list-access-keys --user-name suspicious-user
aws iam delete-access-key --user-name suspicious-user --access-key-id <key-id>

# AWS: Revoke all IAM session tokens
aws iam delete-role-policy --role-name suspicious-role --policy-name *

# Azure: Disable service principal
az ad app delete --id <compromised-app-id>

# Block suspicious IP at security group level
aws ec2 revoke-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 22 \
  --cidr <attacker-ip>/32
```

**Phase 2: Investigation & Forensics (0-120 minutes)**
```bash
# AWS: Export CloudTrail logs for analysis
aws s3 sync s3://cloudtrail-logs-bucket s3://forensics-bucket/cloudtrail/

# AWS: Preserve EC2 instance for forensics
aws ec2 create-image \
  --instance-id i-xxxxx \
  --name forensics-backup-$(date +%s)

# Azure: Export activity logs
az monitor activity-log list \
  --resource-group secure-multicloud-prod-rg \
  > activity-logs-$(date +%Y%m%d).json

# Network analysis
aws ec2 describe-network-interfaces \
  --filters Name=association.public-ip,Values=<suspicious-ip>
```

**Phase 3: Infrastructure Rebuild (120-240 minutes)**
```bash
# Option 1: Destroy and recreate everything
terraform destroy -auto-approve

# Option 2: Selective rebuild (if specific resource compromised)
terraform destroy \
  -target=aws_instance.suspicious_instance

# Option 3: Rotate credentials and rebuild IAM roles
terraform apply -target=aws_iam_role.app -auto-approve

# Verify rotation
terraform output | grep role
```

**Phase 4: Post-Incident (240-360 minutes)**
```bash
# 1. Establish new baseline
terraform output -json > baseline-post-incident.json

# 2. Update security policies
# Review and update security.tf based on learnings

# 3. Restore applications
# Redeploy with updated secrets from Secrets Manager

# 4. Communication & Documentation
# - Incident report
# - Timeline of events
# - Root cause analysis
# - Preventive measures
```

---

## Backup & Recovery Strategy

### Backup Schedule
- **Terraform State**: Continuous (via S3/Azure backend with versioning)
- **Application Data**: Daily (snapshots, replication)
- **Logs**: Continuous (immutable archive)
- **Configuration**: Real-time (Infrastructure as Code)

### Backup Locations

#### AWS
- Primary S3 bucket: `logs-bucket` (same region)
- Cross-region replica: `logs-bucket-us-west-2` (different region)
- Terraform state: S3 backend with versioning
- CloudTrail: Dedicated bucket with MFA delete

#### Azure
- Primary Storage: `logstorage` (same region)
- Geo-redundant: GRS replication to secondary region
- Terraform state: Azure Storage with versioning
- Activity Logs: Log Analytics workspace retention

### Backup Validation

```bash
# Monthly backup validation
# AWS
aws s3 sync s3://logs-bucket s3://validation-bucket --dryrun
aws s3api head-object --bucket logs-bucket --key critical-file

# Azure
az storage blob list --account-name logstorage --container-name logs
az storage blob show --account-name logstorage --container-name logs --name critical-file
```

---

## Failover Procedures

### Automatic Failover
- **Health Checks**: CloudWatch/Monitor alarms trigger 
- **Notification**: SNS/Action Groups alert operations
- **Decision Point**: Manual approval required for failover
- **Execution**: Terraform automation executes in secondary region

### Manual Failover Execution
```bash
# 1. Declare disaster
# Notify stakeholders via war room call

# 2. Run failover script
./scripts/failover.sh aws us-west-2

# 3. Monitor progress
terraform apply -auto-approve

# 4. Validate state
terraform output
aws ec2 describe-vpcs
```

---

## Testing & Maintenance

### Quarterly DR Drill

```bash
# 1. Simulate primary region failure
# Use Terraform to deploy to secondary region

# 2. Execute failover procedure
# Run complete recovery steps

# 3. Measure metrics
RTO_ACHIEVED=$(( $(date +%s) - START_TIME ))
echo "RTO Achieved: $RTO_ACHIEVED seconds"

# 4. Document findings
# Log any issues or optimizations

# 5. Update procedures
# Incorporate lessons learned
```

### Annual Full Recovery Test

- Complete destruction of primary infrastructure
- Full recovery from backups
- Full application deployment
- Full validation and security scan
- Update RTO/RPO documentation with actual results

---

## Documentation & Communication

### Change Log
- All infrastructure changes logged in Terraform commits
- Backup performed after each significant change
- State versioning enables point-in-time recovery

### Communication Plan
1. **Detection**: Alert to on-call engineer (immediate)
2. **Investigation**: War room call within 15 minutes
3. **Status Updates**: Every 30 minutes to leadership
4. **Resolution**: Final notification when systems restored
5. **Post-Incident**: Review within 48 hours

### Stakeholder Notification
- Operations team: Every 30 minutes
- Management: Every hour
- Customers (if applicable): Every 2 hours
- Post-incident review: Within 48 hours

---

## Key Contacts

| Role | Name | Phone | Email |
|------|------|-------|-------|
| On-Call Engineer | [Name] | [Phone] | [Email] |
| Engineering Manager | [Name] | [Phone] | [Email] |
| Security Lead | [Name] | [Phone] | [Email] |
| AWS Account Manager | [Name] | [Phone] | [Email] |
| Azure Account Manager | [Name] | [Phone] | [Email] |

---

## Related Documents
- [OPERATIONS.md](OPERATIONS.md) - Operational procedures
- [SECURITY.md](SECURITY.md) - Security posture
- [DEPLOYMENT.md](DEPLOYMENT.md) - Initial deployment
- [THREAT_MODEL.md](THREAT_MODEL.md) - Security threats

---

## Appendix: Recovery Scripts

### failover.sh
```bash
#!/bin/bash
set -e

CLOUD=$1  # aws or azure
REGION=$2 # target region

echo "Starting failover to $CLOUD region $REGION"

if [ "$CLOUD" == "aws" ]; then
  cd terraform/aws
  sed -i "s/aws_region = .*/aws_region = \"$REGION\"/" terraform.tfvars
  terraform init
  terraform apply -auto-approve
elif [ "$CLOUD" == "azure" ]; then
  cd terraform/azure
  sed -i "s/azure_region = .*/azure_region = \"$REGION\"/" terraform.tfvars
  terraform init
  terraform apply -auto-approve
fi

echo "Failover complete. Verify outputs:"
terraform output
```

### validate_backup.sh
```bash
#!/bin/bash

echo "Validating backups..."

# AWS validation
aws s3api head-bucket --bucket logs-bucket
aws dynamodb describe-table --table-name terraform-locks

# Azure validation
az storage account show --resource-group secure-multicloud-prod-rg --name logstorage
az storage blob exists --account-name logstorage --container-name logs --name backup

echo "Backup validation complete"
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-01-XX | Platform Team | Initial version |

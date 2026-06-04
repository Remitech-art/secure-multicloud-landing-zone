# Cost Optimization Guide

## Executive Summary

This guide provides strategies and recommendations for optimizing costs across the Secure Multi-Cloud Landing Zone while maintaining security, reliability, and compliance posture.

---

## Cost Breakdown & Analysis

### AWS Monthly Cost Estimate

| Component | Usage | Unit Cost | Monthly |
|-----------|-------|-----------|---------|
| **VPC** | 1 | $0 | $0 |
| **Subnets** | 4 | $0 each | $0 |
| **NAT Gateway** | 2 | $32.00/month | $64 |
| **Elastic IPs** | 2 | $3.65/month | $7.30 |
| **S3 Logs** | 100 GB | $0.023/GB | $2.30 |
| **CloudWatch Logs** | 50 GB | $0.50/GB | $25 |
| **CloudTrail** | 1 trail | $2.00/month | $2 |
| **KMS Keys** | 3 | $1/month each | $3 |
| **EC2 (Bastion, t3.micro)** | 1 | $7/month | $7 |
| **CloudWatch Alarms** | 5 | $0.10/alarm | $0.50 |
| **VPN Gateway** | 1 | $32/month | $32 |
| **Data Transfer** | 10 GB/month | $0.09/GB | $0.90 |
| **Estimated Total (AWS)** | | | **~$143/month** |

### Azure Monthly Cost Estimate

| Component | Usage | Unit Cost | Monthly |
|-----------|-------|-----------|---------|
| **Virtual Network** | 1 | $0 | $0 |
| **Subnets** | 3 | $0 each | $0 |
| **NSGs** | 2 | $0 each | $0 |
| **Public IP** | 1 (Bastion) | $2.50/month | $2.50 |
| **Azure Bastion** | 1 | $19.25/month | $19.25 |
| **Storage Account** | 2 (500GB) | $0.0184/GB | $18.40 |
| **Log Analytics** | 1 (100 GB) | $3.25/GB | $325 |
| **Application Insights** | 1 | $2.99/month | $2.99 |
| **Key Vault** | 1 | $0.50/month | $0.50 |
| **Network Watcher** | 1 | $1/month | $1 |
| **Estimated Total (Azure)** | | | **~$370/month** |

### Combined Monthly Cost: ~$513

---

## Optimization Strategies

### 1. NAT Gateway Optimization (AWS)

#### Current Configuration
- 2 x NAT Gateways ($64/month)
- Each AZ has dedicated NAT for HA

#### Optimization Options

**Option A: Shared NAT Gateway**
```hcl
# Single NAT gateway across both subnets
# Cost Savings: $32/month
# Trade-off: Single point of failure for outbound connectivity

resource "aws_nat_gateway" "main" {
  count = 1  # Changed from length(var.private_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[0].id
}
```

**Option B: NAT Instance (VPN)** 
- Use smaller EC2 instance instead of managed NAT
- Cost: ~$15/month (t3.small)
- Trade-off: Manual patching, reduced reliability

**Option C: VPC Endpoints (AWS PrivateLink)**
```hcl
# For S3 and DynamoDB access, use gateway endpoints
# Cost Savings: No data transfer charges

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = aws_route_table.private[*].id
}
```

#### Implementation (if chosen)
```bash
# Update variables
sed -i 's/enable_nat_gateway = true/enable_nat_gateway = false/' terraform.tfvars

# Review changes
terraform plan

# Apply optimization
terraform apply
```

**Estimated Savings: $32-48/month**

---

### 2. S3 & Log Storage Optimization (AWS)

#### Current Configuration
- All logs in Standard storage
- 365-day retention
- No lifecycle policies optimized

#### Optimization Strategy

```hcl
# Implement tiered storage lifecycle

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "archive-logs"
    status = "Enabled"

    # 30 days → Standard-IA (37% cheaper than Standard)
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # 90 days → Glacier (60% cheaper than Standard)
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # 365 days → Glacier Deep Archive (95% cheaper)
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete after 2555 days (7 years)
    expiration {
      days = 2555
    }
  }
}
```

#### Cost Calculation

Assuming 100GB monthly log ingestion:
- Standard (30 days): 3 GB @ $0.023 = $0.07
- Standard-IA (60 days): 6 GB @ $0.0125 = $0.075
- Glacier (275 days): 27.5 GB @ $0.004 = $0.11
- Glacier Deep Archive (1095 days): 109.5 GB @ $0.00099 = $0.11

**Estimated Savings: $0.70/month on storage + request costs**

---

### 3. CloudWatch Logs Optimization (AWS)

#### Current Configuration
- VPC Flow Logs: 90-day retention
- App Logs: 90-day retention
- All logs in premium tier

#### Optimization Strategy

```bash
# Reduce retention for non-critical logs

aws logs put-retention-policy \
  --log-group-name /aws/app/logs \
  --retention-in-days 30  # From 90 days

# Archive important logs to S3 for long-term storage
aws logs create-export-task \
  --log-group-name /aws/app/logs \
  --from $(date -d '30 days ago' +%s)000 \
  --to $(date +%s)000 \
  --destination secure-multicloud-logs \
  --destination-prefix app-logs-archive
```

#### Cost Impact
- 30-day retention vs 90-day: $0.50/GB × 50GB × 2/3 = **$16.67 savings/month**

---

### 4. Log Analytics Optimization (Azure)

#### Current Configuration
- 100GB daily ingestion cap
- 30-day retention
- PerGB2018 pricing tier

#### Optimization Strategy

**Option A: Tiered Approach**
```bash
# Separate hot and cold data

# Hot tier: Application logs (30 days) - Premium
# Cold tier: Archival logs (1 year) - Archive

# Use Azure Data Export to ADLS
az monitor log-analytics workspace data-export create \
  --resource-group secure-multicloud-prod-rg \
  --workspace-name secure-multicloud-law \
  --export-name ArchiveExport \
  --table SecurityEvent \
  --destination-resource-id /subscriptions/.../storageAccounts/archive
```

**Option B: Log Analytics Commitment**
- Annual commitment tier offers 25-30% discount
- From $3.25/GB to ~$2.30/GB

#### Cost Calculation

Current: 100 GB × $3.25 = **$325/month**
With Archive tier + Export:
- Hot (30 days): 10 GB × $3.25 = $32.50
- Archive (export to storage): 300 GB × $0.02/GB = $6

**New Total: ~$40/month**
**Estimated Savings: $285/month**

---

### 5. VM Right-Sizing

#### AWS Bastion
- Current: t3.micro ($7/month)
- Alternative: t3.nano ($3/month)
- Trade-off: Minimal, nano sufficient for SSH bastion

```hcl
# Update variable
variable "bastion_instance_type" {
  default = "t3.nano"  # From t3.micro
}
```

#### Azure Infrastructure
- Current: No compute specified
- Recommendation: If deploying app servers, use spot instances

---

### 6. Reserved Capacity (AWS)

#### NAT Gateway Reserved Hours
```bash
# Estimate usage and purchase 1-year reservation
aws ec2 describe-reserved-instances-offerings \
  --product-description "NAT Gateway" \
  --offering-type "No Upfront"
```

**Potential Savings: 30-40% on NAT Gateway costs**

---

### 7. Data Transfer Optimization

#### AWS Cost

**Current State:**
- Typical: 10 GB/month data transfer out = $0.90

**Optimization:**
1. Use CloudFront for content delivery (if applicable)
2. Use VPC endpoints to avoid NAT charges
3. Consolidate data transfers to batch windows

**Potential Savings: $0.50/month (site-specific)**

#### Azure Cost

**Current State:**
- Outbound: Typically included in premium tiers
- Inbound: Free

**Optimization:**
1. Use Content Delivery Network (CDN) for large transfers
2. Use Service Endpoints for free Azure service access

---

## Total Optimization Roadmap

### Phase 1: Quick Wins (Month 1)
- [ ] Implement S3 tiered lifecycle: **Saves $0.70/month**
- [ ] Reduce CloudWatch retention: **Saves $16.67/month**
- [ ] Downsize bastion to t3.nano: **Saves $4/month**
- **Total Phase 1: $21.37/month (~4% reduction)**

### Phase 2: Structural Changes (Month 2-3)
- [ ] Single NAT Gateway (if acceptable): **Saves $32/month**
- [ ] Implement Azure cold storage: **Saves $285/month**
- [ ] Reserved instances (if commitment possible): **Saves 30% ongoing**
- **Total Phase 2: $317+ /month (~62% reduction)**

### Phase 3: Long-term (Month 3+)
- [ ] Multi-region RI optimization: **Saves 40% data transfer**
- [ ] Right-sizing based on actual usage: **Saves 10-20%**
- [ ] Compliance with cost allocation tags: **Better visibility**

### Post-Optimization Total: ~$190/month (~63% savings)

---

## Tagging & Cost Allocation

### Implement Cost Tags

```hcl
# Update terraform variables
common_tags = {
  CostCenter = "Engineering"
  Environment = "Production"
  Application = "Network"
  Owner = "Platform-Team"
}
```

### Track Costs via Billing

#### AWS Cost Explorer
```bash
# Query costs by tag
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=TAG \
  --filter file://cost-filter.json
```

#### Azure Cost Analysis
```bash
# Group by tags
az costmanagement forecast \
  --type "Usage" \
  --timeframe "MonthToDate" \
  --dataset aggregation=totalCost \
  --dataset grouping=dimension \
  --dataset filter_key=Tags
```

---

## Monitoring & Alerts

### AWS Budget Alert
```bash
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget BudgetName=MonthlyLimit,BudgetLimit={Amount=500,Unit=USD},TimeUnit=MONTHLY,BudgetType=COST

aws budgets create-notification \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget-name MonthlyLimit \
  --notification Type=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=80 \
  --subscribers Type=EMAIL,Value=ops@example.com
```

### Azure Budget Alert
```bash
az consumption budget create \
  --budget-name MonthlyLimit \
  --category cost \
  --amount 500 \
  --time-period start-date=2024-01-01 \
  --notifications-enabled true \
  --notifications-threshold=80 \
  --notifications-threshold-type Forecasted
```

---

## Cost Optimization Best Practices

1. **Review Monthly**: Analyze AWS billing and Azure cost reports
2. **Implement Tags**: Enforce cost center and application tagging
3. **Leverage Savings Plans**: AWS Savings Plans offer flexibility
4. **Reserved Capacity**: Commit to predictable workloads
5. **Spot Instances**: Use for non-critical workloads (if applicable)
6. **Consolidate Services**: Use AWS Billing Consolidation (if multi-account)
7. **Automate Cleanup**: Delete unused resources automatically
8. **Compliance-First**: Don't compromise security for cost

---

## ROI Calculator

### Investment vs. Savings

| Optimization | Implementation Cost | Monthly Savings | Break-even |
|--------------|-------------------|-----------------|-----------|
| Lifecycle Tiering | $0 | $0.70 | Immediate |
| CloudWatch Retention | $0 | $16.67 | Immediate |
| NAT Optimization | $500 (eng time) | $32 | 15.6 months |
| Log Analytics Archive | $1,000 (eng time) | $285 | 3.5 months |
| RI Commitment | $2,000-5,000 upfront | $50-100 | 20-100 months |

### Total Potential Annual Savings: **$1,800-3,800**

---

## References

- [AWS Cost Optimization Practices](https://aws.amazon.com/architecture/cost-optimization/)
- [Azure Cost Management](https://learn.microsoft.com/en-us/azure/cost-management-billing/)
- [Terraform Cost Estimation](https://www.terraform.io/cloud/cost-estimation)
- [Cloud FinOps Foundation](https://www.finops.org/)

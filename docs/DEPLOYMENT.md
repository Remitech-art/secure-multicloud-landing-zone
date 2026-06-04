# Deployment Guide

## Prerequisites

### Required Tools
- **Terraform** >= 1.5.0 ([Download](https://www.terraform.io/downloads))
- **AWS CLI** >= 2.0 ([Download](https://aws.amazon.com/cli/))
- **Azure CLI** >= 2.40 ([Download](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- **Git** >= 2.0
- **jq** (for JSON parsing in scripts)

### Required Permissions

#### AWS
- Root account or Admin IAM user with full permissions to:
  - VPC, Security Groups, IAM, S3, CloudWatch, CloudTrail, KMS
  - Estimated IAM policy: `AdministratorAccess` or equivalent

#### Azure
- Owner or Contributor role on subscription
- Directory role: Application Administrator (for Azure AD setup)

### AWS Account Setup
```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

### Azure Account Setup
```bash
# Login to Azure
az login

# Select subscription (if multiple)
az account set --subscription <subscription-id>

# Verify access
az account show
```

---

## Deployment Steps

> Before deploying cloud landing zones, bootstrap the remote state backends in `terraform/bootstrap/` for AWS, Azure, and GCP.
> See `docs/BOOTSTRAP_PRODUCTION.md` for the exact production bootstrap flow.

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/secure-multicloud-landing-zone.git
cd secure-multicloud-landing-zone
```

### Step 2: AWS Deployment

#### 2.1 Initialize Terraform
```bash
cd terraform/aws

# Initialize working directory
terraform init

# Check syntax
terraform fmt -recursive .
terraform validate
```

#### 2.2 Review Configuration
```bash
# Edit variables for your environment
cp terraform.tfvars terraform.tfvars.backup
nano terraform.tfvars
# Or use your preferred editor

# Key variables to customize:
# - aws_region: Set to your desired region (e.g., us-west-2)
# - project_name: Keep consistent across deployments
# - vpc_cidr: Ensure no overlap with existing networks
# - common_tags: Add your organization tags
```

#### 2.3 Plan Deployment
```bash
# Generate and review plan
terraform plan -out=tfplan

# View plan (optional)
terraform show tfplan
```

#### 2.4 Apply Configuration
```bash
# Deploy infrastructure
terraform apply tfplan

# Note the outputs (VPC ID, subnet IDs, role ARNs, etc.)
terraform output

# Save outputs for reference
terraform output -json > aws-outputs.json
```

#### 2.5 Post-Deployment Configuration
```bash
# Retrieve VPC ID for next steps
VPC_ID=$(terraform output -raw vpc_id)
echo "VPC ID: $VPC_ID"

# (Optional) Deploy bastion host
# See OPERATIONS.md for bastion deployment steps
```

### Step 3: Azure Deployment

#### 3.1 Initialize Terraform
```bash
cd ../../terraform/azure

# Initialize working directory
terraform init

# Check syntax
terraform fmt -recursive .
terraform validate
```

#### 3.2 Review Configuration
```bash
# Edit variables for your environment
cp terraform.tfvars terraform.tfvars.backup
nano terraform.tfvars

# Key variables to customize:
# - azure_region: Set to your desired region (e.g., westus2)
# - project_name: Keep consistent with AWS
# - vnet_cidr: Ensure no overlap with AWS or on-premises
# - common_tags: Match AWS tags for consistency
```

#### 3.3 Plan Deployment
```bash
# Generate and review plan
terraform plan -out=tfplan

# Review plan for correctness
terraform show tfplan
```

#### 3.4 Apply Configuration
```bash
# Deploy infrastructure
terraform apply tfplan

# Note the outputs
terraform output

# Save outputs for reference
terraform output -json > azure-outputs.json
```

#### 3.5 Post-Deployment Configuration
```bash
# Retrieve resource group name
RG_NAME=$(terraform output -raw resource_group_name)
echo "Resource Group: $RG_NAME"

# (Optional) Configure Azure Bastion for SSH/RDP
# See OPERATIONS.md for bastion access procedures
```

---

## Verification Steps

### AWS Verification
```bash
# Verify VPC creation
aws ec2 describe-vpcs --filters Name=cidr,Values=10.0.0.0/16

# Verify subnets
aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID

# Verify security groups
aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC_ID

# Verify IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `secure-multicloud`)]'

# Verify S3 buckets
aws s3 ls | grep secure-multicloud

# Verify CloudTrail
aws cloudtrail describe-trails --region us-east-1

# Verify KMS keys
aws kms list-keys --region us-east-1
```

### Azure Verification
```bash
# Verify resource group
az group show --name $RG_NAME

# Verify virtual network
az network vnet list --resource-group $RG_NAME

# Verify subnets
az network vnet subnet list --resource-group $RG_NAME --vnet-name secure-multicloud-vnet

# Verify NSGs
az network nsg list --resource-group $RG_NAME

# Verify storage accounts
az storage account list --resource-group $RG_NAME

# Verify Key Vault
az keyvault list --resource-group $RG_NAME

# Verify Log Analytics
az monitor log-analytics workspace list --resource-group $RG_NAME
```

---

## Optional: S3 Backend Configuration (AWS)

### Create Backend Infrastructure
```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### Update Terraform Backend Configuration
```bash
# In terraform/aws/provider.tf, uncomment backend block:
cat >> terraform/aws/backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "aws/landing-zone/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
EOF

# Migrate state to S3
cd terraform/aws
terraform init
# Respond 'yes' to copy state to new backend
```

---

## Optional: Azure Backend Configuration

### Create Backend Infrastructure
```bash
# Create resource group for backend
az group create \
  --name tfstate-rg \
  --location eastus

# Create storage account
az storage account create \
  --resource-group tfstate-rg \
  --name tfstate$(date +%s) \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true

# Create blob container
az storage container create \
  --name tfstate \
  --account-name <storage-account-name>
```

### Update Terraform Backend Configuration
```bash
# In terraform/azure/provider.tf, configure backend:
cat >> terraform/azure/backend.tf << 'EOF'
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate<timestamp>"
    container_name       = "tfstate"
    key                  = "azure/landing-zone/terraform.tfstate"
  }
}
EOF

# Migrate state
cd terraform/azure
terraform init
```

---

## State Management Best Practices

### Backup State Files
```bash
# AWS: Use S3 versioning (already enabled above)
# Azure: Use storage account soft delete

# Manual backup
terraform state pull > terraform.state.backup

# Store securely
gpg --encrypt terraform.state.backup
rm terraform.state.backup
```

### State File Security
1. **Never commit to git**: Add to `.gitignore`
2. **Encrypt in transit**: Use S3/Azure backend encryption
3. **Encrypt at rest**: KMS/CMK encryption
4. **Access control**: IAM/RBAC restrictions
5. **Audit logging**: Enable CloudTrail/Activity Logs

---

## Troubleshooting

### AWS Issues

#### "UnauthorizedOperation" Error
```bash
# Verify IAM permissions
aws iam get-user

# Check current caller identity
aws sts get-caller-identity
```

#### "InvalidParameterValue" for CIDR
```bash
# Verify CIDR is valid
terraform console
cidrhost("10.0.0.0/16", 0)  # Should return 10.0.0.0
```

#### VPC Creation Fails
```bash
# Check for existing resources with same name
aws ec2 describe-vpcs --filters Name=tag:Name,Values=secure-multicloud-vpc

# Delete conflicting resource manually if needed
aws ec2 delete-vpc --vpc-id vpc-xxxxx
```

### Azure Issues

#### "Authentication failed" Error
```bash
# Re-authenticate
az logout
az login

# Verify subscription
az account show
```

#### Resource Group Deployment Failed
```bash
# Check deployment status
az deployment group list --resource-group $RG_NAME

# View deployment errors
az deployment group show --resource-group $RG_NAME \
  --name <deployment-name>
```

### Terraform Common Issues

#### "Backend initialization required"
```bash
# Initialize backend
terraform init
```

#### "State lock timeout"
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK-ID>
```

#### "Version constraints mismatch"
```bash
# Update terraform version
terraform version
# Or update version constraints in provider.tf
```

---

## Cleanup / Destruction

### Destroy AWS Infrastructure
```bash
cd terraform/aws

# Review destruction plan
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# Confirm deletion
# Type 'yes' when prompted
```

### Destroy Azure Infrastructure
```bash
cd terraform/azure

# Review destruction plan
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# Confirm deletion
# Type 'yes' when prompted
```

### Full Cleanup
```bash
# Remove local state
rm -rf terraform/.terraform/
rm terraform.tfstate*

# Remove outputs
rm aws-outputs.json azure-outputs.json

# Clean up credentials
rm ~/.aws/config ~/.aws/credentials  # Use with caution!
```

---

## Next Steps

1. **Access Infrastructure**: See [OPERATIONS.md](OPERATIONS.md)
2. **Monitor Infrastructure**: Refer to CloudWatch/Monitor dashboards
3. **Deploy Applications**: Use AWS/Azure deployment tools
4. **Security Hardening**: Review [SECURITY.md](SECURITY.md)
5. **Disaster Recovery**: Plan using [DISASTER_RECOVERY.md](DISASTER_RECOVERY.md)

---

## Support & Documentation

- **AWS Terraform Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Azure Terraform Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Terraform CLI**: https://www.terraform.io/cli/commands
- **AWS Architecture**: https://docs.aws.amazon.com/
- **Azure Architecture**: https://learn.microsoft.com/en-us/azure/

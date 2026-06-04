# State Management

This document describes the recommended remote state setup for production deployments.

AWS (recommended production setup)
- Create an S3 bucket: `secure-multicloud-terraform-state`
- Enable bucket encryption (SSE-KMS) and versioning
- Create DynamoDB table: `secure-multicloud-terraform-locks` for state locking
- Example init: `terraform init -backend-config=terraform/aws/backend.tf`

Azure
- Create resource group `secure-multicloud-tfstate-rg`
- Create storage account `securemulticloudtfstate` (lowercase, 3-24 chars)
- Create blob container `tfstate` with private access
- Example init: `terraform init -backend-config=terraform/azure/backend.tf`

GCP
- Create GCS bucket: `secure-multicloud-terraform-state`
- Enable versioning and CMEK if required
- Example init: `terraform init -backend-config=terraform/gcp/backend.tf`

Notes
- The repository includes concrete backend config files for production; ensure the specified backend resources exist before running `terraform init`.
- Use the bootstrap directories in `terraform/bootstrap/` to provision remote state resources before you initialize the main cloud deployments.
- For non-production environments, duplicate the backend file and adjust names accordingly.
# Terraform State Management

## Overview

Production Terraform deployments require reliable remote state management with encryption, locking, and versioning. This ensures team collaboration, prevents state corruption, and supports recoverability.

## AWS Remote State

- Backend: `s3`
- Bucket: `secure-multicloud-terraform-state`
- Key: `aws/landing-zone/terraform.tfstate`
- Region: `us-east-1`
- Encryption: enabled
- Locking: `DynamoDB` table `secure-multicloud-terraform-locks`

### Production Requirements

- Create an S3 bucket with versioning and encryption enabled.
- Create a DynamoDB table with `lock_id` as the primary key.
- Restrict access to the bucket and table via IAM policies.
- Use `terraform init` with the backend configured for the correct environment.

## Azure Remote State

- Backend: `azurerm`
- Resource group: `secure-multicloud-tfstate-rg`
- Storage account: `securemulticloudtfstate`
- Container: `tfstate`
- Key: `azure/landing-zone/terraform.tfstate`

### Production Requirements

- Enable Azure Storage encryption at rest.
- Use managed identity or SAS-based access controls for Terraform.
- Restrict storage account access to approved identities only.
- Implement soft delete and container versioning if available.

## GCP Remote State

- Backend: `gcs`
- Bucket: `secure-multicloud-terraform-state`
- Prefix: `gcp/landing-zone/terraform/state`

### Production Requirements

- Enable object versioning on the Cloud Storage bucket.
- Restrict bucket access to Terraform service accounts only.
- Use bucket IAM bindings and organization policies to prevent public access.
- Store backend credentials centrally and avoid hard-coding them.

## Best Practices

- Keep backend configuration out of public source control when possible.
- Use environment-specific backend configs for dev/staging/prod.
- Use Terraform workspaces or separate state buckets for isolation.
- Regularly audit backend access patterns and state bucket permissions.

# Production Bootstrap and Remote State Initialization

This guide describes the safe bootstrap workflow for remote state backends and identity wiring required for production deployment.

## Purpose

- Provision cloud-native remote state backends for AWS, Azure, and GCP.
- Establish identity trust for GitHub Actions using OIDC/workload identity.
- Ensure the landing zone can initialize and operate with production-grade backends.

## AWS Bootstrap Steps

1. Change into the AWS bootstrap directory:

```bash
cd terraform/bootstrap/aws
```

2. Initialize the bootstrap working directory:

```bash
terraform init
```

3. Review and apply the bootstrap resources:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

4. Confirm the backend resources exist:

```bash
terraform output
```

5. Return to the main AWS deployment directory and initialize with the backend config:

```bash
cd ../../aws
terraform init
```

6. Run plan and apply on the main AWS landing zone:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Azure Bootstrap Steps

1. Change into the Azure bootstrap directory:

```bash
cd terraform/bootstrap/azure
```

2. Initialize and provision Azure backend resources:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

3. Confirm outputs and backend readiness.

4. Change to the main Azure deployment directory and initialize Terraform:

```bash
cd ../../azure
terraform init
```

5. Plan and apply the Azure landing zone.

## GCP Bootstrap Steps

1. Change into the GCP bootstrap directory:

```bash
cd terraform/bootstrap/gcp
```

2. Initialize and provision the GCS bucket for remote state:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

3. Confirm outputs and backend readiness.

4. Return to the main GCP deployment directory and initialize Terraform:

```bash
cd ../../gcp
terraform init
```

5. Plan and apply the GCP landing zone.

## Identity Wiring Notes

The repository now includes dedicated files for GitHub Actions identity wiring:

- `terraform/aws/identity.tf`
- `terraform/azure/identity.tf`
- `terraform/gcp/identity.tf`

Set the following variables in your cloud environment before running the main deployment:

- `github_organization`
- `github_repository`

For AWS, the AWS IAM OIDC provider and a GitHub-trusted role are created.
For Azure, an Azure AD federated identity credential is created for the landing zone application.
For GCP, a workload identity pool and provider are created to bind GitHub Actions to the platform service account.

## Validation

After bootstrap and main deployment, verify:

- Remote state buckets/containers exist and are private.
- DynamoDB lock table exists for AWS state locking.
- GitHub Actions OIDC identity resources are provisioned.
- `terraform init` succeeds in `terraform/aws`, `terraform/azure`, and `terraform/gcp`.

## Operational Governance

Use GitHub environment protection and branch protection for the repository that contains this landing zone. This ensures that manually approved production deployments are enforced after the backend and identity bootstrap are provisioned.

# Disaster Recovery Runbook

RTO / RPO
- Target RTO: 2 hours for critical services
- Target RPO: 1 hour for critical stateful data

Backup Strategy
- AWS: Snapshot critical EBS volumes, S3 replication, RDS snapshots
- Azure: Snapshot VMs, Storage redundancy and replication, SQL backups
- GCP: Persistent disk snapshots, Cloud Storage versioning, automated exports

Recovery Steps (high level)
- Identify affected region and services
- Promote standby resources or run redeploy using Terraform state backups
- Restore data from latest snapshots and validate integrity

Failover Considerations
- DNS TTL management and automated DNS failover
- Cross-region data replication and consistency
# Disaster Recovery Runbook

## Objectives

- Define Recovery Time Objective (RTO) and Recovery Point Objective (RPO).
- Document backup, restore, and failover procedures for AWS, Azure, and GCP.
- Provide clear operational runbooks for recovery execution.

## RTO / RPO

- RTO: 1-4 hours for critical platform components.
- RPO: 15 minutes for transactional systems, 24 hours for batch systems.

## Backup Strategy

### AWS
- Enable EBS snapshots for critical instances.
- Enable S3 versioning and cross-region replication for logs and artifacts.
- Backup RDS or databases using automated snapshots.

### Azure
- Enable Azure Backup for VMs and databases.
- Use Blob Storage soft delete and immutable storage for critical logs.
- Configure backup policies for key vaults and storage accounts.

### GCP
- Use Cloud Storage lifecycle and versioning for critical data.
- Use snapshots for persistent disks.
- Configure backup schedules for managed databases.

## Recovery Procedures

### AWS Recovery
1. Validate the scope of the outage.
2. Use Terraform state to identify created resources.
3. Restore S3 bucket versions or recover from cross-region replication.
4. Restore EC2 instances from snapshots or launch replacement instances.
5. Rehydrate database backups and validate connectivity.

### Azure Recovery
1. Validate impacted resource groups and subscriptions.
2. Recover VMs from Azure Backup restore points.
3. Restore storage blobs from snapshots or soft-delete recovery.
4. Recover database backups from Azure SQL or managed services.

### GCP Recovery
1. Validate impacted projects and buckets.
2. Recover disks from snapshots.
3. Restore Cloud Storage objects from version history.
4. Rebuild services using Terraform state and restored data.

## Post-Recovery Actions

- Validate application health and connectivity.
- Run security checks and audit logs.
- Update the incident report and root cause analysis.
- Review and improve recovery runbooks.

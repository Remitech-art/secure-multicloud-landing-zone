# Security Architecture & Design

## Executive Summary

This multi-cloud landing zone implements enterprise-grade security controls aligned with the CIA Triad (Confidentiality, Integrity, Availability) and industry best practices including NIST Cybersecurity Framework, AWS Well-Architected Framework, and Azure Security Best Practices.

---

## Security Principles

### 1. Least Privilege Access
- **IAM/RBAC**: Only necessary permissions granted
- **Service Roles**: Scoped permissions for applications
- **Network Segmentation**: DMZ, application, and database tiers
- **Time-Limited Access**: Session-based credentials

### 2. Defense in Depth
- **Multiple Security Layers**: Network, application, data
- **Layered Validation**: Input, business logic, output
- **Redundant Controls**: Overlapping security mechanisms

### 3. Zero Trust Architecture
- **Verify Every Access**: No implicit trust
- **Assume Breach Mentality**: Design for compromise
- **Encrypt Everything**: Data in transit and at rest
- **Monitor Continuously**: Real-time threat detection

---

## AWS Security Architecture

### Identity and Access Management (IAM)

#### Bastion Host Role
```hcl
Role: secure-multicloud-bastion-*
Permissions:
  - SSM: Systems Manager Session Manager access
  - EC2: Describe instances and security groups
  - CloudWatch Logs: Write application logs
  - S3: Read logs and configuration
Policies: Least privilege via resource restrictions
```

#### Application Role
```hcl
Role: secure-multicloud-app-*
Permissions:
  - CloudWatch: Put metrics and logs
  - X-Ray: Write trace data
  - Secrets Manager: Read secrets
Policies: No S3 access; application-scoped permissions
```

### Network Security

#### Security Groups

**Bastion Security Group**
- **Inbound**: SSH (22) - Restricted to admin IPs
- **Outbound**: All traffic allowed
- **Strategy**: Jump server for private resource access

**Application Security Group**
- **Inbound**: SSH (22) from Bastion SG, HTTP (80), HTTPS (443) from VPC
- **Outbound**: All traffic allowed
- **Strategy**: Private tier, no direct internet access

**VPC Endpoints Security Group**
- **Inbound**: HTTPS (443) from VPC
- **Outbound**: All traffic allowed
- **Purpose**: Secure AWS service access without internet

#### Network ACLs
- Stateless rules for additional filtering
- Allow all traffic by default (Security Groups primary control)
- Custom rules for specific compliance requirements

### Data Protection

#### Encryption at Rest
- **S3**: KMS-managed encryption (Customer Master Key)
- **CloudTrail Logs**: KMS encryption
- **CloudWatch Logs**: KMS encryption
- **EBS Volumes** (future): KMS encryption mandatory
- **RDS** (future): KMS encryption required

#### Encryption in Transit
- **S3**: HTTPS only (bucket policy denies HTTP)
- **CloudTrail**: TLS 1.2+
- **VPC Flow Logs**: HTTPS transmission
- **TLS Certificate Management**: AWS-managed or custom

#### Key Management
- **KMS Keys**: Customer-managed for compliance
- **Key Rotation**: Automatic rotation enabled
- **Access Control**: IAM-based key usage policies
- **Audit Trail**: CloudTrail logs all key usage

### Monitoring and Detection

#### CloudTrail (API Audit Logging)
- **Enabled**: Global trail across all regions
- **Log File Validation**: Enable integrity checking
- **S3 Storage**: Encrypted with KMS
- **Retention**: Logs retained for 365 days minimum
- **Queries**: Detect unauthorized API calls

#### VPC Flow Logs
- **Scope**: All traffic (ACCEPT and REJECT)
- **Destination**: CloudWatch Logs with KMS encryption
- **Retention**: 90 days
- **Analysis**: Detect suspicious traffic patterns

#### CloudWatch Monitoring
- **Metrics**: VPC, EC2, NAT Gateway health
- **Logs**: Application logs, system logs
- **Alarms**: Alert on anomalies
- **Dashboard**: Centralized security posture

#### GuardDuty (Optional Enhancement)
- **Purpose**: AI-based threat detection
- **Findings**: Unauthorized API calls, compromised instances
- **Integration**: SNS notifications to security team

---

## Azure Security Architecture

### Identity and Access Management (RBAC)

#### Service Principal
```
Application: secure-multicloud-app
Permissions:
  - Contributor role on Resource Group (design limitation)
  - Future: Scope to specific resources
Access: Client ID + Tenant ID authentication
```

#### Managed Identity
```
Identity: secure-multicloud-app-identity
Type: User-assigned
Permissions: Contributor on Resource Group
Purpose: Application authentication without secrets
```

### Network Security

#### Network Security Groups (NSGs)

**Public NSG**
- **Inbound**: 
  - HTTP (80): Any source
  - HTTPS (443): Any source
- **Outbound**: All traffic allowed
- **Strategy**: Load balancer or public endpoint tier

**Private NSG**
- **Inbound**: Only internal VNET traffic (10.1.0.0/16)
- **Outbound**: All traffic allowed
- **Strategy**: Application tier, no direct internet

#### Azure Bastion
- **Purpose**: Secure RDP/SSH without public IPs
- **Authentication**: Azure AD integrated
- **Encryption**: TLS 1.2+ for all connections
- **Audit**: All sessions logged to Storage

### Data Protection

#### Encryption at Rest
- **Storage Accounts**: Encryption enabled by default
- **Blobs**: Microsoft-managed or CMK
- **Disks**: Encryption at host enabled
- **Key Vault**: CMK for customer-managed encryption

#### Encryption in Transit
- **HTTPS Only**: Enforced via storage policies
- **TLS 1.2+**: Minimum protocol version
- **VNet Integration**: Private endpoints for Azure services

#### Key Management
- **Key Vault**: Centralized key and secret storage
- **Access Policies**: RBAC for key operations
- **Key Rotation**: Manual or automatic
- **Audit**: All operations logged

### Monitoring and Detection

#### Azure Monitor
- **Metrics**: CPU, memory, network bandwidth
- **Alerts**: Threshold-based notifications
- **Action Groups**: Route alerts to teams

#### Log Analytics
- **Workspace**: Centralized log aggregation
- **Retention**: 30-730 days configurable
- **KQL Queries**: Custom analysis
- **Security Insights**: SIEM-like capabilities

#### Application Insights
- **Purpose**: Application performance monitoring
- **Traces**: Request/response analysis
- **Exceptions**: Error tracking and alerting
- **Dependencies**: Cross-service call tracking

#### Azure Security Center
- **Defender Plans**: Advanced threat protection
- **Recommendations**: Security posture improvement
- **Incidents**: Automated threat response

#### Activity Logs
- **Scope**: Control plane operations
- **Retention**: 90 days minimum
- **Export**: Archive to storage for compliance

---

## Threat Model (STRIDE)

### Spoofing Identity
**Threats:**
- Unauthorized access via compromised credentials
- Man-in-the-middle attacks on inter-service communication

**Mitigations:**
- Strong authentication (MFA, OAuth 2.0)
- TLS 1.2+ for all encrypted channels
- IAM roles with resource-based policies
- Network segmentation prevents lateral movement

### Tampering with Data
**Threats:**
- Unauthorized modification of data
- Unauthorized modification of configuration

**Mitigations:**
- Data encryption at rest (KMS)
- API audit logging (CloudTrail, Activity Logs)
- S3 versioning and MFA delete
- Read-only replicas where applicable
- Immutable logs with integrity checking

### Repudiation
**Threats:**
- Denial of operations performed
- Untraced unauthorized access

**Mitigations:**
- Comprehensive audit logging (CloudTrail)
- Log integrity validation (log file validation)
- Encrypted log storage in separate account
- Retention policies (365+ days)
- Integration with SIEM systems

### Information Disclosure
**Threats:**
- Exposure of sensitive data
- Unauthorized data access
- Data breach via network sniffing

**Mitigations:**
- Encryption at rest (S3, storage accounts, logs)
- Encryption in transit (TLS 1.2+, HTTPS only)
- Network segmentation and NSGs/Security Groups
- IAM least privilege access
- Private subnets for sensitive workloads
- VPC endpoints for AWS service access

### Denial of Service (DoS)
**Threats:**
- Resource exhaustion attacks
- DDoS attacks on public endpoints
- Logging system overload

**Mitigations:**
- Multi-AZ deployment for resilience
- Managed DDoS protection (AWS Shield, Azure DDoS Protection)
- Elastic scaling capabilities
- CloudWatch/Monitor alarms for capacity
- Network segmentation limits blast radius
- Rate limiting at application layer

### Elevation of Privilege
**Threats:**
- Unauthorized privilege escalation
- Misuse of service roles
- Stolen credentials elevation

**Mitigations:**
- Least privilege IAM/RBAC roles
- No hardcoded credentials
- Secrets stored in Key Vault/Secrets Manager
- Regular access reviews
- Service principals with restricted permissions
- MFA for admin access
- Session recording (Azure Bastion)

---

## Compliance Mapping

### CIA Triad Alignment

| Pillar | Principle | Implementation |
|--------|-----------|-----------------|
| **Confidentiality** | Authorized access only | IAM/RBAC, encryption, NSGs |
| | Data in transit protection | TLS 1.2+, HTTPS only |
| | Data at rest protection | KMS, CMK encryption |
| **Integrity** | Data consistency | Versioning, audit logs, backups |
| | Change tracking | CloudTrail, Activity Logs |
| | Configuration management | Terraform IaC, validation |
| **Availability** | Fault tolerance | Multi-AZ, NAT HA, replication |
| | Performance | Auto-scaling, monitoring |
| | Recovery | Backups, disaster recovery plan |

---

## Security Operations

### Incident Response
1. **Detection**: CloudWatch alarms, Security Center findings
2. **Investigation**: Log analysis, network forensics
3. **Containment**: Security group modification, instance termination
4. **Eradication**: Patch vulnerabilities, update credentials
5. **Recovery**: Restore from backups, redeploy infrastructure
6. **Lessons Learned**: Update runbooks and documentation

### Key Rotation
- **KMS Keys**: Automatic rotation enabled (annually)
- **Secrets**: Manual rotation (quarterly minimum)
- **Credentials**: Automated via CI/CD rotation jobs
- **Certificates**: 30-day renewal reminders

### Access Reviews
- **Monthly**: Review IAM role permissions
- **Quarterly**: Review user access
- **Annually**: Comprehensive security audit

---

## Future Enhancements

1. **Advanced Threat Protection**: GuardDuty, Security Center advanced plans
2. **SIEM Integration**: Splunk, Datadog, or Azure Sentinel
3. **Encryption Key Hardware**: CloudHSM, Dedicated HSM
4. **VPC/VNET Peering**: Direct cloud interconnection
5. **WAF/DDoS**: Web Application Firewall deployment
6. **Secrets Rotation**: Automated credential rotation
7. **Patch Management**: Automated patching pipeline

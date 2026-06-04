# Threat Model Analysis (STRIDE)

## Overview

This document provides a detailed threat model analysis for the Secure Multi-Cloud Landing Zone using the STRIDE methodology (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege).

---

## System Assumptions

### Trust Boundaries
1. **Cloud Provider Boundary**: AWS and Azure infrastructure is trusted
2. **Network Boundary**: Internal VPC/VNET is more trusted than internet
3. **Application Boundary**: Custom applications are potential vectors
4. **User Boundary**: Authenticated users are partially trusted

### Data Classification
- **Public**: No confidentiality or integrity requirements
- **Internal**: For use within the organization
- **Confidential**: Limited distribution, legal implications
- **Restricted**: Highly sensitive, compliance-bound

---

## Threat Analysis by Component

### 1. Internet Gateway / Load Balancer

#### Spoofing Identity
**Threat**: Attacker impersonates legitimate user/service
- **Risk**: High - Direct internet exposure
- **Mitigation**:
  - HTTPS enforcement with valid certificates
  - Request validation and sanitization
  - WAF rules for common attacks
  - Rate limiting on authentication endpoints

#### Tampering with Data
**Threat**: Attacker modifies traffic/requests
- **Risk**: Medium - If HTTPS enforced
- **Mitigation**:
  - TLS 1.2+ only
  - HTTPS redirect rules
  - Content Security Policy headers
  - Signature verification for APIs

#### Denial of Service
**Threat**: Attacker overwhelms service with requests
- **Risk**: High - Public endpoint
- **Mitigation**:
  - Auto-scaling configured
  - DDoS protection (AWS Shield, Azure DDoS)
  - Rate limiting and throttling
  - CDN integration (CloudFront, Azure CDN)

#### Information Disclosure
**Threat**: Attacker gains access to sensitive data
- **Risk**: Critical
- **Mitigation**:
  - No sensitive data in URLs/logs
  - Error messages don't leak system info
  - Proper HTTP headers (X-Frame-Options, etc.)
  - HSTS enforcement

---

### 2. Public Subnets

#### Spoofing Identity
**Threat**: Attacker impersonates bastion host or load balancer
- **Risk**: Medium
- **Mitigation**:
  - Instance identity documents (AWS IMDSv2)
  - Azure Managed Identity
  - Security group restrictions

#### Tampering with Data
**Threat**: Attacker modifies data in transit
- **Risk**: Low - NACLs provide filtering
- **Mitigation**:
  - Network ACLs restrict traffic
  - Encryption for sensitive inter-service comms
  - VPC endpoints for AWS service access

#### Elevation of Privilege
**Threat**: Bastion compromise leads to private subnet access
- **Risk**: Critical
- **Mitigation**:
  - Bastion hardening (minimal packages)
  - SSH key rotation
  - Session logging and monitoring
  - Bastion security group restrictions

#### Information Disclosure
**Threat**: Network traffic sniffing in public subnet
- **Risk**: Medium
- **Mitigation**:
  - TLS 1.2+ encryption
  - VPC Flow Logs for detection
  - No sensitive data in logs

---

### 3. Private Subnets (Application Tier)

#### Elevation of Privilege
**Threat**: Compromised app escalates to infrastructure control
- **Risk**: Critical
- **Mitigation**:
  - Scoped IAM roles (no wildcard permissions)
  - Secrets Manager for credentials
  - No hardcoded passwords/keys
  - Regular security patching
  - Minimal application privileges

#### Information Disclosure
**Threat**: Application access to unauthorized data
- **Risk**: High
- **Mitigation**:
  - Database encryption with column-level controls
  - S3 bucket policies restrict access
  - IAM policy enforcement
  - Data classification and tagging

#### Tampering with Data
**Threat**: Malicious code modifies application state
- **Risk**: High
- **Mitigation**:
  - Code signing and verification
  - Container image scanning (Trivy)
  - Immutable infrastructure deployments
  - Configuration as Code validation

#### Denial of Service
**Threat**: Application resource exhaustion
- **Risk**: Medium
- **Mitigation**:
  - Resource limits on containers
  - Connection pooling
  - Query optimization
  - Auto-scaling policies

---

### 4. Storage Layer (S3 / Azure Blob)

#### Information Disclosure
**Threat**: Unauthorized bucket/container access
- **Risk**: Critical
- **Mitigation**:
  - Block Public Access enabled
  - Bucket policies with least privilege
  - Encryption with Customer Master Keys
  - VPC endpoint access only
  - S3 Macie for sensitive data detection

#### Tampering with Data
**Threat**: Unauthorized object modification
- **Risk**: Critical
- **Mitigation**:
  - Versioning enabled
  - MFA Delete for production buckets
  - Immutable versions
  - Object lock (S3)
  - Access logging enabled

#### Denial of Service
**Threat**: Massive data deletion or uploads
- **Risk**: High
- **Mitigation**:
  - Lifecycle policies for old versions
  - Backup strategies
  - Access logging for audit
  - S3 Intelligent-Tiering for costs

---

### 5. Logging and Monitoring Systems

#### Repudiation
**Threat**: Attacker deletes evidence of attacks
- **Risk**: Critical
- **Mitigation**:
  - Immutable log storage
  - Log integrity validation (CloudTrail)
  - Separate AWS account for logs (future)
  - Centralized SIEM (future)
  - Encryption prevents unauthorized modification

#### Information Disclosure
**Threat**: Logs contain sensitive data
- **Risk**: High
- **Mitigation**:
  - No secrets in logs
  - Encryption at rest (KMS)
  - Encryption in transit (HTTPS)
  - Access controls on log groups
  - Regular log retention review

#### Denial of Service
**Threat**: Log system overwhelmed
- **Risk**: Medium
- **Mitigation**:
  - Log retention limits
  - Sampling for high-volume logs
  - Separate capacity for critical logs
  - Archive to cheaper storage

---

### 6. IAM / RBAC Systems

#### Elevation of Privilege
**Threat**: Attacker gains administrative access
- **Risk**: Critical
- **Mitigation**:
  - Least privilege roles by default
  - Regular access reviews
  - MFA for admin actions
  - Role assumption logging
  - Condition-based policies

#### Tampering with Data
**Threat**: Attacker modifies IAM policies
- **Risk**: Critical
- **Mitigation**:
  - IAM policy validation in CI/CD
  - Change notifications
  - Approval workflow for sensitive changes
  - CloudTrail tracking all changes
  - Resource-based policies as backup

#### Repudiation
**Threat**: Attacker claims they didn't perform action
- **Risk**: High
- **Mitigation**:
  - CloudTrail logs all API calls
  - User assumption tracking
  - MFA requirement logging
  - Audit logs immutable

---

### 7. Key Management (KMS)

#### Elevation of Privilege
**Threat**: Attacker gains key decryption permissions
- **Risk**: Critical
- **Mitigation**:
  - KMS key policies restrict usage
  - IAM policy enforcement
  - No wildcard permissions
  - Key alias separation

#### Tampering with Data
**Threat**: Attacker modifies key policies
- **Risk**: Critical
- **Mitigation**:
  - Key policy validation
  - CMK rotation enabled
  - CloudTrail tracks policy changes
  - Separate key per data classification

#### Information Disclosure
**Threat**: Attacker gains plaintext via key access
- **Risk**: Critical
- **Mitigation**:
  - Scoped DecryptDataKey permissions
  - Encryption context validation
  - Key usage logging
  - Hardware-backed keys (CloudHSM) for future

---

## Risk Assessment Matrix

| Threat | Probability | Impact | Risk Level | Priority |
|--------|-------------|--------|-----------|----------|
| Data Breach via Public Endpoint | Medium | Critical | High | 1 |
| Compromised Bastion Access | Medium | Critical | High | 1 |
| Log Tampering | Low | Critical | High | 2 |
| Privilege Escalation | Medium | Critical | High | 1 |
| DDoS Attack | Medium | High | High | 2 |
| Insider Threat | Low | Critical | Medium | 3 |
| Misconfiguration Exposure | Medium | High | High | 2 |
| Key Compromise | Low | Critical | Medium | 3 |
| IAM Policy Bypass | Low | Critical | Medium | 3 |
| Network Sniffing | Low | Medium | Low | 4 |

---

## Risk Mitigation Roadmap

### Phase 1 (Current)
- ✅ Network segmentation (public/private subnets)
- ✅ Encryption at rest and in transit
- ✅ IAM least privilege roles
- ✅ VPC Flow Logs and CloudTrail
- ✅ Security group restrictions

### Phase 2 (Months 1-3)
- [ ] AWS Shield advanced DDoS protection
- [ ] GuardDuty threat detection
- [ ] Automated patching pipeline
- [ ] WAF deployment
- [ ] Secrets rotation automation

### Phase 3 (Months 3-6)
- [ ] SIEM integration (Splunk/Datadog)
- [ ] Behavior analytics
- [ ] Automated incident response
- [ ] Multi-factor authentication (MFA)
- [ ] Hardware Security Module (CloudHSM)

### Phase 4 (Months 6-12)
- [ ] Zero Trust Architecture
- [ ] Service mesh security
- [ ] End-to-end encryption
- [ ] Compliance automation (CIS, PCI-DSS)
- [ ] Disaster recovery testing

---

## Compliance Considerations

### NIST Cybersecurity Framework Alignment

| Function | Approach |
|----------|----------|
| **Identify** | Asset inventory via tagging, access control matrix |
| **Protect** | Encryption, IAM, security groups, monitoring |
| **Detect** | CloudWatch/Monitor, VPC Flow Logs, CloudTrail |
| **Respond** | Runbooks, incident classification, automation |
| **Recover** | Backup strategies, failover procedures, testing |

### Baseline Controls (CIS AWS Foundations)
- [ ] Multi-factor authentication (MFA) for IAM users
- [ ] CloudTrail enabled in all regions
- [ ] CloudTrail log file validation enabled
- [ ] CloudTrail logs encrypted at rest
- [ ] S3 bucket public access blocked
- [ ] VPC Flow Logs enabled
- [ ] Security groups restrict traffic

---

## Lessons Learned & Improvements

### From Threat Model
1. **Key Dependency**: Bastion compromise is critical path - enhance monitoring
2. **Data Classification**: Implement consistent tagging for data tier access
3. **Network Monitoring**: VPC Flow Logs insufficient - consider third-party IDS
4. **Compliance Automation**: Manual reviews don't scale - invest in continuous compliance

### Technical Debt
1. Separate logging account for immutability
2. Multi-region deployment for resilience
3. Secrets rotation automation
4. Advanced threat detection (GuardDuty, Defender)

---

## Appendix: Attack Scenarios

### Scenario 1: Compromised Bastion → Private Network

**Attack Path**:
1. SSH key stolen from developer laptop
2. Attacker connects to bastion host
3. Private SSH key used to access app servers
4. Attacker downloads database credentials from app config
5. Database breach and data exfiltration

**Mitigations**:
- Bastion session logging to CloudWatch
- Real-time anomaly detection
- IP whitelist for bastion access
- Secrets in Secrets Manager (not files)
- Database encryption and encryption keys in KMS

**Detection**:
- VPC Flow Logs showing unusual ports (port 3306)
- CloudWatch Logs anomaly detection
- GuardDuty unusual API calls
- Security Center anomaly alerts

---

### Scenario 2: Supply Chain Attack via Dependencies

**Attack Path**:
1. Attacker compromises npm/pip package
2. Package included in application
3. Container image scanned but vulnerability missed
4. Container deployed with backdoor
5. Application data exfiltrated via command injection

**Mitigations**:
- Container image scanning (Trivy, Snyk)
- Dependency scanning in CI/CD
- SBOM generation and tracking
- Signed images and policy enforcement
- Runtime security monitoring

**Detection**:
- Image scanning failures in CI/CD
- Unusual network connections from container
- Privilege escalation attempts
- File system modifications

---

### Scenario 3: Infrastructure as Code Injection

**Attack Path**:
1. Attacker creates PR with malicious Terraform
2. Security review misses vulnerability
3. Code merged to main branch
4. CI/CD deploys insecure infrastructure
5. S3 bucket accidentally public, data exposed

**Mitigations**:
- Terraform validation in CI/CD
- Security scanning (tfsec, Checkov)
- Manual code review process
- Infrastructure diff approval gates
- Automated remediation policies

**Detection**:
- Failed Terraform plan due to policy violations
- Drift detection from desired state
- S3 block public access alarm
- CloudTrail API call anomalies

---

## Conclusion

This threat model provides a foundation for security posture assessment. Regular updates as architecture evolves and new threats emerge are recommended. Quarterly threat model reviews with architecture, security, and operations teams ensure continued relevance and effectiveness.

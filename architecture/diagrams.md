# Architecture Diagrams

## Multi-Cloud Landing Zone - High-Level Overview

```mermaid
graph TB
    Internet["🌐 Internet"]
    
    subgraph AWS["AWS Landing Zone (10.0.0.0/16)"]
        AWSIGW["📡 Internet Gateway"]
        AWSpub1["Public Subnet 1<br/>10.0.1.0/24"]
        AWSpub2["Public Subnet 2<br/>10.0.2.0/24"]
        AWSpriv1["Private Subnet 1<br/>10.0.10.0/24"]
        AWSpriv2["Private Subnet 2<br/>10.0.11.0/24"]
        AWSNAT1["🔄 NAT Gateway 1"]
        AWSNAT2["🔄 NAT Gateway 2"]
        AWSBastion["🖥️ Bastion Host"]
        AWSApp["🏃 App Servers"]
        AWSS3["📦 S3 Logs<br/>Encrypted"]
        AWSLogs["📊 CloudWatch<br/>VPC Flow Logs"]
        AWSTrail["🔍 CloudTrail"]
    end
    
    subgraph Azure["Azure Landing Zone (10.1.0.0/16)"]
        AzurePublicLB["🔗 Load Balancer"]
        AzurePub1["Public Subnet 1<br/>10.1.1.0/24"]
        AzurePub2["Public Subnet 2<br/>10.1.2.0/24"]
        AzurePriv1["Private Subnet 1<br/>10.1.10.0/24"]
        AzurePriv2["Private Subnet 2<br/>10.1.11.0/24"]
        AzureBastion["🛡️ Azure Bastion"]
        AzureApp["🏃 App Servers"]
        AzureStorage["💾 Blob Storage<br/>Encrypted"]
        AzureLogs["📊 Log Analytics<br/>Flow Logs"]
        AzureKV["🔐 Key Vault"]
    end
    
    subgraph Security["🔐 Security & Monitoring"]
        IAM["👤 IAM/RBAC<br/>Least Privilege"]
        Encryption["🔒 KMS/CMK<br/>Encryption"]
        NSG["🚪 Security Groups<br/>& NSGs"]
        Monitoring["📈 Monitoring<br/>& Alerts"]
    end
    
    Internet -->|HTTP/HTTPS| AWSIGW
    Internet -->|HTTP/HTTPS| AzurePublicLB
    
    AWSIGW --> AWSpub1
    AWSIGW --> AWSpub2
    AWSpub1 --> AWSBastion
    AWSpub2 --> AWSNAT1
    AWSpub1 --> AWSNAT2
    
    AWSNAT1 --> AWSpriv1
    AWSNAT2 --> AWSpriv2
    AWSpriv1 --> AWSApp
    AWSpriv2 --> AWSApp
    
    AWSApp --> AWSS3
    AWSApp --> AWSLogs
    AWSTrail --> AWSS3
    
    AzurePublicLB --> AzurePub1
    AzurePublicLB --> AzurePub2
    AzurePub1 --> AzureBastion
    AzurePub2 --> AzureApp
    
    AzurePriv1 --> AzureApp
    AzurePriv2 --> AzureApp
    
    AzureApp --> AzureStorage
    AzureApp --> AzureLogs
    AzureApp --> AzureKV
    
    IAM -.->|Policies| AWS
    IAM -.->|Policies| Azure
    Encryption -.->|Keys| AWSS3
    Encryption -.->|Keys| AzureStorage
    NSG -.->|Filtering| AWS
    NSG -.->|Filtering| Azure
    Monitoring -.->|Alarms| AWSLogs
    Monitoring -.->|Alarms| AzureLogs
    
    style AWS fill:#FF9900,stroke:#232F3E,color:#fff
    style Azure fill:#0078D4,stroke:#fff,color:#fff
    style Security fill:#34A048,stroke:#fff,color:#fff
```

---

## AWS Architecture - Detailed

```mermaid
graph TB
    Internet["🌐 Internet / Users"]
    Route53["Route 53<br/>DNS"]
    
    subgraph AWSVPC["AWS VPC (10.0.0.0/16)"]
        IGW["📡 Internet Gateway"]
        
        subgraph PublicSubnets["Public Subnets (DMZ)"]
            PubSub1["Subnet 10.0.1.0/24<br/>us-east-1a"]
            PubSub2["Subnet 10.0.2.0/24<br/>us-east-1b"]
        end
        
        subgraph PrivateSubnets["Private Subnets (App Tier)"]
            PrivSub1["Subnet 10.0.10.0/24<br/>us-east-1a"]
            PrivSub2["Subnet 10.0.11.0/24<br/>us-east-1b"]
        end
        
        NGW1["🔄 NAT Gateway 1<br/>us-east-1a"]
        NGW2["🔄 NAT Gateway 2<br/>us-east-1b"]
        EIP1["Elastic IP 1"]
        EIP2["Elastic IP 2"]
        
        Bastion["🖥️ Bastion Host<br/>t3.micro"]
        AppServer1["🏃 App Server 1<br/>us-east-1a"]
        AppServer2["🏃 App Server 2<br/>us-east-1b"]
        
        subgraph SecurityLayers["Security Groups"]
            BastionSG["Bastion SG<br/>SSH: 22<br/>Admin IPs only"]
            AppSG["App SG<br/>SSH from Bastion<br/>HTTP/HTTPS: 80, 443"]
            VPCEndpointSG["VPC Endpoint SG<br/>HTTPS: 443"]
        end
        
        NACL["🚪 Network ACLs<br/>Stateless Filtering"]
        
        subgraph Storage["Storage Layer"]
            S3Logs["📦 S3 Logs Bucket<br/>Encrypted with KMS"]
            S3CloudTrail["📦 S3 CloudTrail<br/>API Audit Logs"]
        end
        
        subgraph Monitoring["Monitoring & Logging"]
            CloudWatch["📊 CloudWatch<br/>Metrics & Logs"]
            VPCFlowLogs["🔍 VPC Flow Logs<br/>Network Analysis"]
            CloudTrail["🔍 CloudTrail<br/>API Audit Trail"]
            KMS["🔐 KMS Keys<br/>CMK Encryption"]
        end
        
        subgraph IAMLayer["Identity & Access"]
            IAMBastion["👤 Bastion Role<br/>SSM, EC2 Describe"]
            IAMApp["👤 App Role<br/>CloudWatch, S3"]
        end
    end
    
    Internet --> Route53
    Route53 --> IGW
    IGW --> PubSub1
    IGW --> PubSub2
    
    PubSub1 --> Bastion
    PubSub2 --> NGW1
    PubSub1 --> NGW2
    
    NGW1 --> EIP1
    NGW2 --> EIP2
    
    NGW1 --> PrivSub1
    NGW2 --> PrivSub2
    
    PrivSub1 --> AppServer1
    PrivSub2 --> AppServer2
    
    Bastion -.->|SSH| AppServer1
    Bastion -.->|SSH| AppServer2
    
    AppServer1 --> S3Logs
    AppServer2 --> S3Logs
    
    CloudTrail --> S3CloudTrail
    VPCFlowLogs -.->|Captures| PubSub1
    VPCFlowLogs -.->|Captures| PubSub2
    VPCFlowLogs -.->|Captures| PrivSub1
    VPCFlowLogs -.->|Captures| PrivSub2
    
    BastionSG -.->|Protects| Bastion
    AppSG -.->|Protects| AppServer1
    AppSG -.->|Protects| AppServer2
    
    KMS -.->|Encrypts| S3Logs
    KMS -.->|Encrypts| S3CloudTrail
    KMS -.->|Encrypts| CloudWatch
    
    IAMBastion -.->|Permits| Bastion
    IAMApp -.->|Permits| AppServer1
    IAMApp -.->|Permits| AppServer2
    
    style AWSVPC fill:#FF9900,stroke:#232F3E,stroke-width:3px,color:#fff
    style PublicSubnets fill:#FFB366,stroke:#232F3E,color:#000
    style PrivateSubnets fill:#FFCC99,stroke:#232F3E,color:#000
    style SecurityLayers fill:#D4534F,stroke:#fff,color:#fff
    style Storage fill:#34A048,stroke:#fff,color:#fff
    style Monitoring fill:#5294CF,stroke:#fff,color:#fff
    style IAMLayer fill:#FF6B6B,stroke:#fff,color:#fff
```

---

## Azure Architecture - Detailed

```mermaid
graph TB
    Users["👥 Users"]
    CDN["🚀 Azure CDN"]
    AppGW["🔗 Application Gateway<br/>Load Balancer"]
    
    subgraph AzureRG["Resource Group<br/>secure-multicloud-prod"]
        subgraph AZUREVNET["VNET (10.1.0.0/16)"]
            subgraph PublicSubnets["Public Subnets"]
                PubSub1["Subnet 10.1.1.0/24<br/>eastus"]
                PubSub2["Subnet 10.1.2.0/24<br/>eastus"]
            end
            
            subgraph PrivateSubnets["Private Subnets"]
                PrivSub1["Subnet 10.1.10.0/24<br/>App Tier"]
                PrivSub2["Subnet 10.1.11.0/24<br/>App Tier"]
            end
            
            subgraph BastionSubnet["Bastion Subnet"]
                BastionSubnetDef["AzureBastionSubnet<br/>10.1.100.0/24"]
            end
            
            NSGPublic["🚪 NSG Public<br/>HTTP/HTTPS: 80, 443"]
            NSGPrivate["🚪 NSG Private<br/>VNET Only"]
            NSGBastion["🚪 NSG Bastion<br/>SSH/RDP: 22, 3389"]
            
            Bastion["🛡️ Azure Bastion<br/>RDP/SSH Access"]
            AppVM1["🏃 App VM 1<br/>eastus"]
            AppVM2["🏃 App VM 2<br/>eastus"]
        end
        
        subgraph Storage["Storage & Secrets"]
            StorageLogs["💾 Storage Logs<br/>GRS Replication<br/>Encrypted"]
            StorageDiag["💾 Diagnostics<br/>Storage"]
            KeyVault["🔐 Key Vault<br/>Secrets & Keys"]
        end
        
        subgraph Monitoring["Monitoring & Logging"]
            LAW["📊 Log Analytics<br/>Workspace"]
            AppInsights["📈 App Insights<br/>Performance"]
            Monitor["🔍 Azure Monitor<br/>Metrics & Alerts"]
            ActivityLogs["📋 Activity Logs<br/>Control Plane"]
        end
        
        subgraph Identity["Identity & Access"]
            AAD["👤 Azure AD<br/>Service Principal"]
            ManagedID["🔑 Managed Identity<br/>App Access"]
            RBAC["👥 RBAC<br/>Role Assignments"]
        end
        
        NW["🔍 Network Watcher<br/>Flow Logs"]
    end
    
    Users --> CDN
    CDN --> AppGW
    AppGW --> PubSub1
    AppGW --> PubSub2
    
    PubSub1 --> Bastion
    PubSub2 --> AppVM1
    
    PrivSub1 --> AppVM1
    PrivSub2 --> AppVM2
    
    Bastion -.->|RDP/SSH| AppVM1
    Bastion -.->|RDP/SSH| AppVM2
    
    AppVM1 --> StorageLogs
    AppVM2 --> StorageLogs
    
    AppVM1 --> KeyVault
    AppVM2 --> KeyVault
    
    LAW -.->|Ingests| ActivityLogs
    LAW -.->|Ingests| AppInsights
    LAW -.->|Ingests| NW
    
    NW -.->|Flow Logs| NSGPublic
    NW -.->|Flow Logs| NSGPrivate
    
    AAD -.->|Identity| ManagedID
    RBAC -.->|Controls| AppVM1
    RBAC -.->|Controls| AppVM2
    
    Monitor -.->|Alerts| LAW
    
    style AzureRG fill:#0078D4,stroke:#fff,stroke-width:3px,color:#fff
    style AZUREVNET fill:#50E6FF,stroke:#0078D4,color:#000
    style PublicSubnets fill:#90EE90,stroke:#0078D4,color:#000
    style PrivateSubnets fill:#FFB366,stroke:#0078D4,color:#000
    style BastionSubnet fill:#FFD700,stroke:#0078D4,color:#000
    style Storage fill:#8B4789,stroke:#fff,color:#fff
    style Monitoring fill:#FF6B9D,stroke:#fff,color:#fff
    style Identity fill:#00D9FF,stroke:#fff,color:#000
```

---

## Security Architecture - Defense in Depth

```mermaid
graph TB
    Internet["🌐 Internet"]
    
    subgraph L0["Layer 0: DDoS Protection"]
        DDoS["AWS Shield / Azure DDoS<br/>Network-level protection"]
    end
    
    subgraph L1["Layer 1: Edge Security"]
        WAF["🛡️ WAF<br/>Application-level filtering"]
        Firewall["🚪 Firewall Rules<br/>Port/Protocol filtering"]
    end
    
    subgraph L2["Layer 2: Network Segmentation"]
        IGW["📡 Internet Gateway<br/>Controlled Access"]
        NSG["🚪 NSG / Security Groups<br/>Stateful Inspection"]
        NACL["🚪 NACLs<br/>Stateless Filtering"]
    end
    
    subgraph L3["Layer 3: Authentication & Authorization"]
        IAM["👤 IAM / RBAC<br/>Role-based Access"]
        MFA["🔐 MFA<br/>Multi-factor Auth"]
        ServiceAccount["🔑 Service Principals<br/>Managed Identities"]
    end
    
    subgraph L4["Layer 4: Data Protection"]
        Encryption["🔒 Encryption at Rest<br/>KMS / CMK"]
        TransitEnc["🔒 Encryption in Transit<br/>TLS 1.2+, HTTPS"]
        Masking["🔏 Data Masking<br/>Sensitive Fields"]
    end
    
    subgraph L5["Layer 5: Logging & Monitoring"]
        Audit["🔍 Audit Logging<br/>CloudTrail / Activity Logs"]
        FlowLogs["📊 VPC Flow Logs<br/>Network Traffic Analysis"]
        Monitoring["📈 Continuous Monitoring<br/>CloudWatch / Monitor"]
        SIEM["🚨 SIEM Integration<br/>Threat Detection"]
    end
    
    subgraph L6["Layer 6: Incident Response"]
        Detection["🔔 Anomaly Detection<br/>GuardDuty / Defender"]
        Response["⚡ Automated Response<br/>Runbooks & Playbooks"]
        Forensics["🔍 Forensics<br/>Log Analysis & Evidence"]
    end
    
    Internet --> DDoS
    DDoS --> WAF
    WAF --> Firewall
    Firewall --> IGW
    IGW --> NSG
    NSG --> NACL
    
    NACL --> IAM
    IAM --> MFA
    MFA --> ServiceAccount
    
    ServiceAccount --> Encryption
    ServiceAccount --> TransitEnc
    Encryption --> Masking
    
    Masking --> Audit
    Audit --> FlowLogs
    FlowLogs --> Monitoring
    Monitoring --> SIEM
    
    SIEM --> Detection
    Detection --> Response
    Response --> Forensics
    
    style L0 fill:#FF6B6B,stroke:#fff,color:#fff
    style L1 fill:#FF8E72,stroke:#fff,color:#fff
    style L2 fill:#FFA726,stroke:#fff,color:#fff
    style L3 fill:#FFD700,stroke:#000,color:#000
    style L4 fill:#90EE90,stroke:#000,color:#000
    style L5 fill:#5294CF,stroke:#fff,color:#fff
    style L6 fill:#8B4789,stroke:#fff,color:#fff
```

---

## Data Flow - Network Communication

```mermaid
graph LR
    subgraph Public["Public Internet"]
        User["👤 End User<br/>203.0.113.0"]
    end
    
    subgraph AWS["AWS"]
        ELB["⚖️ Elastic Load Balancer<br/>443 HTTPS"]
        Bastion["🖥️ Bastion Host<br/>Public Subnet"]
        App["🏃 App Server<br/>Private Subnet<br/>10.0.10.x"]
    end
    
    subgraph Azure["Azure"]
        AppGW["🔗 App Gateway<br/>443 HTTPS"]
        AzureApp["🏃 App Server<br/>Private Subnet<br/>10.1.10.x"]
    end
    
    subgraph Logs["Logging Infrastructure"]
        CloudTrail["📊 CloudTrail"]
        ActivityLog["📊 Activity Logs"]
        S3["📦 S3 Logs Bucket<br/>Encrypted"]
        BlobStore["💾 Azure Storage<br/>Encrypted"]
    end
    
    subgraph Cross["Cross-Cloud (Optional)"]
        VPN["🔐 VPN Gateway<br/>Encrypted Tunnel<br/>IPSec"]
    end
    
    User -->|1. HTTPS Request<br/>443| ELB
    ELB -->|2. Forward to<br/>App Server| App
    App -->|3. Process<br/>Request| App
    
    Bastion -->|4. SSH Access<br/>22| App
    App -->|5. Response| User
    
    ELB -->|6. Log Events| CloudTrail
    App -->|7. Send Logs| S3
    CloudTrail -->|8. Store Logs| S3
    
    User -->|9. HTTPS Request<br/>443| AppGW
    AppGW -->|10. Forward| AzureApp
    AzureApp -->|11. Response| User
    
    AppGW -->|12. Log Events| ActivityLog
    AzureApp -->|13. Send Logs| BlobStore
    ActivityLog -->|14. Archive| BlobStore
    
    App -->|15. (Optional)<br/>Sync| VPN
    VPN -->|16. Encrypted| AzureApp
    
    style Public fill:#FFE4E1,stroke:#000
    style AWS fill:#FF9900,stroke:#232F3E,color:#fff
    style Azure fill:#0078D4,stroke:#fff,color:#fff
    style Logs fill:#34A048,stroke:#fff,color:#fff
    style Cross fill:#8B4789,stroke:#fff,color:#fff
```

---

## Disaster Recovery Flow

```mermaid
graph TB
    Primary["🟢 Primary Region<br/>Active"]
    Secondary["🔴 Secondary Region<br/>Standby"]
    
    subgraph ReplicationSetup["Replication Setup"]
        S3Sync["S3 → S3 Cross-Region<br/>Replication"]
        TFSync["Terraform State Sync<br/>Version Control"]
        DBSync["Database Replication<br/>Async Writes"]
    end
    
    subgraph DisasterDetection["Disaster Detection"]
        Monitoring["📊 Health Checks<br/>Every 60 seconds"]
        FailureDetect["🔔 Failure Detection<br/>Regional Down"]
        AlertTeam["📞 Team Alert<br/>SNS Notification"]
    end
    
    subgraph FailoverProcess["Failover Process"]
        FailoverStart["⚡ Start Failover<br/>Manual Approval"]
        TFApply["Terraform Apply<br/>Secondary Region"]
        DataRecover["📦 Recover Data<br/>From Replication"]
        DRTest["✅ DR Test<br/>Validate State"]
    end
    
    subgraph PostRecovery["Post-Recovery"]
        Monitor["📊 Monitor Stability<br/>24 hours"]
        Failback["↩️ Plan Failback<br/>Back to Primary"]
        Review["📋 Post-Incident<br/>Review & Document"]
    end
    
    Primary -->|Continuous| S3Sync
    Primary -->|Versioning| TFSync
    Primary -->|Replication| DBSync
    
    Monitoring -->|Health Check| Primary
    Monitoring -->|Failure?| FailureDetect
    FailureDetect -->|Yes| AlertTeam
    
    AlertTeam -->|Approve| FailoverStart
    FailoverStart -->|Deploy| TFApply
    TFApply -->|Restore| DataRecover
    DataRecover -->|Validate| DRTest
    
    DRTest -->|Success| Monitor
    Monitor -->|24hrs OK| Failback
    Failback -->|Complete| Review
    
    style Primary fill:#90EE90,stroke:#000,stroke-width:2px
    style Secondary fill:#FFB6C1,stroke:#000,stroke-width:2px
    style DisasterDetection fill:#FF6B6B,stroke:#fff,color:#fff
    style FailoverProcess fill:#FFA500,stroke:#fff,color:#fff
    style PostRecovery fill:#5294CF,stroke:#fff,color:#fff
```

---

## Data Classification & Access Control Matrix

```mermaid
graph TB
    subgraph DataClass["Data Classification"]
        Public["🟢 Public<br/>No Restrictions<br/>Examples: Marketing, Blog"]
        Internal["🟡 Internal<br/>Organization Only<br/>Examples: Configs, Logs"]
        Confidential["🔴 Confidential<br/>Limited Access<br/>Examples: Credentials, DB"]
        Restricted["⚫ Restricted<br/>Highest Control<br/>Examples: PII, Secrets"]
    end
    
    subgraph AccessControl["Access Control"]
        Everyone["👥 Everyone"]
        Engineers["👨‍💻 Engineers"]
        Security["🔒 Security Team"]
        Admin["👑 Admin Only"]
    end
    
    subgraph Storage["Storage & Encryption"]
        Public -->|S3 Standard| PublicBucket["📦 Public Bucket"]
        Internal -->|S3 + KMS| InternalBucket["📦 Internal Bucket<br/>Encrypted"]
        Confidential -->|S3 + CMK| ConfBucket["📦 Confidential Bucket<br/>CMK Encrypted"]
        Restricted -->|S3 + CMK<br/>MFA Delete| RestrictBucket["📦 Restricted Bucket<br/>CMK + MFA Delete"]
    end
    
    subgraph SecurityControls["Security Controls"]
        Public -->|Allow All| Everyone
        Internal -->|Restricted| Engineers
        Confidential -->|Highly Restricted| Security
        Restricted -->|On-Demand Only| Admin
    end
    
    style DataClass fill:#34A048,stroke:#fff,color:#fff
    style AccessControl fill:#5294CF,stroke:#fff,color:#fff
    style Storage fill:#FF9900,stroke:#232F3E,color:#fff
    style SecurityControls fill:#FF6B6B,stroke:#fff,color:#fff
```

---

## Tagging Strategy & Resource Organization

```mermaid
graph TB
    subgraph TaggingStrategy["Tagging Strategy"]
        Environment["Environment<br/>dev/staging/prod"]
        Project["Project<br/>landing-zone"]
        Owner["Owner<br/>team name"]
        CostCenter["CostCenter<br/>department"]
        DataClass["DataClass<br/>public/internal/confidential"]
        Compliance["Compliance<br/>compliance tags"]
    end
    
    subgraph ResourceOrganization["Resource Organization"]
        AWS["AWS Resources<br/>Tags applied at VPC level"]
        Azure["Azure Resources<br/>Tags applied at RG level"]
        Terraform["Terraform<br/>common_tags variable"]
    end
    
    subgraph Applications["Applications"]
        App1["App Server 1"]
        App2["App Server 2"]
        Storage["Storage Bucket"]
    end
    
    subgraph Queries["Query & Cost Allocation"]
        CostExplorer["AWS Cost Explorer<br/>Group by Tags"]
        CostAnalysis["Azure Cost Analysis<br/>Filter by Tags"]
        Reports["Billing Reports<br/>By Department"]
    end
    
    Environment -->|Identifies| AWS
    Environment -->|Identifies| Azure
    Project -->|Identifies| Terraform
    Owner -->|Identifies| Terraform
    CostCenter -->|Allocates| CostExplorer
    CostCenter -->|Allocates| CostAnalysis
    
    AWS -->|Applied to| App1
    AWS -->|Applied to| Storage
    Azure -->|Applied to| App2
    
    CostExplorer -->|Generates| Reports
    CostAnalysis -->|Generates| Reports
    
    style TaggingStrategy fill:#FFD700,stroke:#000
    style ResourceOrganization fill:#90EE90,stroke:#000
    style Applications fill:#5294CF,stroke:#fff,color:#fff
    style Queries fill:#FF6B6B,stroke:#fff,color:#fff
```

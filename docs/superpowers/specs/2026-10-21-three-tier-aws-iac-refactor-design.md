# Three-Tier AWS Infrastructure as Code with Terraform - Design Specification

**Date:** 2026-10-21  
**Status:** Approved by User  
**Author:** DevOps Engineering Team  

---

## 1. Project Overview & Architecture Alignment

This specification aligns the **Three-Tier AWS Infrastructure as Code with Terraform** project directly with the user-provided architectural blueprint (`3-TIER ARCHITECTURE ON AWS (UAT ENV)`), incorporating production-grade elasticity, zero-trust security, and automated state management.

### Key Architectural Decisions:
1. **True 3-Tier Compute Separation with Elastic ASGs:**
   - **Tier 1 (Presentation / Web):** Application Load Balancer in Public Subnets forwarding traffic (Port 80) to a **Frontend Auto Scaling Group** across 2 Availability Zones.
   - **Tier 2 (Application / Logic):** **Backend Auto Scaling Group** deployed across Private App Subnets, accessible on Port 8080 **strictly from the Frontend Security Group**.
   - **Tier 3 (Database / Data):** **Amazon RDS PostgreSQL 15.7** deployed in dedicated DB Subnets, accessible on Port 5432 **strictly from the Backend Security Group**.
2. **Subnet Topology & IP Addressing (Aligned with Architectural Blueprint):**
   - **Public Subnet 1 (`us-east-1a`):** `10.0.1.0/24` (ALB Node A, Frontend Web ASG)
   - **Public Subnet 2 (`us-east-1b`):** `10.0.16.0/24` (ALB Node B, Frontend Web ASG, NAT Gateway & EIP)
   - **Private App Subnet 1 (`us-east-1a`):** `10.0.24.0/24` (Backend App ASG)
   - **Private App Subnet 2 (`us-east-1b`):** `10.0.48.0/24` (Backend App ASG)
   - **Database Subnet 1 (`us-east-1a`):** `10.0.64.0/24` (RDS Primary)
   - **Database Subnet 2 (`us-east-1b`):** `10.0.96.0/24` (RDS Multi-AZ Standby)
3. **Database Selection:** PostgreSQL 15.7 with configurable `multi_az` (`false` in Dev/UAT for Free Tier cost efficiency; `true` in Prod for automated synchronous failover across AZs).
4. **Dynamic AMI & Hardening:** Dynamic lookup using `data "aws_ami" "amazon_linux_2023"`. Enforce IMDSv2 (`http_tokens = "required"`). Zero open SSH ports — instances utilize AWS Systems Manager (SSM) Session Manager via IAM instance profiles.
5. **Remote Backend & Concurrency:** S3 Bucket (AES256 encrypted, versioned, public access blocked) and DynamoDB state lock table in `global/s3_backend`.
6. **Multi-Environment Architecture:** Independent directories for `envs/dev`, `envs/uat`, and `envs/prod` with isolated `.tfstate` paths in S3, environment-specific variables, and `.tfvars.example` files.
7. **Hygiene & Bug Fixes:** Standardize AWS Provider version `aws ~> 5.0`, configure `.gitignore` (ignoring `.tfvars`, `.terraform/`, `*.tfstate`), and set up `.tflint.hcl`.

---

## 2. Architecture Diagram

```text
========================================================================================================
                                 AWS REGION: us-east-1 (VPC 10.0.0.0/16)
========================================================================================================
                                                  |
                                       [ Internet Gateway (IGW) ]
                                                  |
  +-----------------------------------------------+-----------------------------------------------+
  |                                                                                               |
  |   +-----------------------------------------------+   +-----------------------------------+   |
  |   |              AVAILABILITY ZONE A              |   |        AVAILABILITY ZONE B        |   |
  |   |                                               |   |                                   |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   |  | Public Subnet 1 (10.0.1.0/24)           |  |   |  | Public Subnet 2 (10.0.16.0/24|  |   |
  |   |  | - ALB Node A                            |  |   |  | - ALB Node B                |  |   |
  |   |  | - Frontend ASG Web Server (Node A)      |  |   |  | - Frontend ASG Web Server B |  |   |
  |   |  |                                         |  |   |  | - NAT Gateway & Elastic IP   |  |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   |                      |                        |   |                |                  |   |
  |   |                      | (HTTP 8080)            |   | (HTTP 8080)    |                  |   |
  |   |                      v                        |   |                v                  |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   |  | Private App Subnet 1 (10.0.24.0/24)     |  |   |  | Private App Subnet 2 (48/24)|  |   |
  |   |  | - Backend ASG App Server (Node A)       |  |   |  | - Backend ASG App Server B  |  |   |
  |   |  | - SSM Managed (Zero SSH)                |  |   |  | - SSM Managed (Zero SSH)    |  |   |
  |   |  | - Egress updates via NAT GW             |  |   |  | - Egress updates via NAT GW |  |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   |                      |                        |   |                |                  |   |
  |   |                      | (PostgreSQL 5432)      |   | (PostgreSQL)   |                  |   |
  |   |                      v                        |   |                v                  |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   |  | DB Subnet 1 (10.0.64.0/24)              |  |   |  | DB Subnet 2 (10.0.96.0/24)  |  |   |
  |   |  | - Primary RDS PostgreSQL 15.7           |  |   |  | - Standby RDS PostgreSQL    |  |   |
  |   |  |                                         |==|==>|   (Multi-AZ Synchronous in Prod) |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   +-----------------------------------------------+   +-----------------------------------+   |
  |                                                                                               |
  +-----------------------------------------------------------------------------------------------+

SECURITY GROUP FIREWALL CHAIN:
1. Public Internet ----> ALB Security Group (Ports 80/443 from 0.0.0.0/0)
2. ALB SG -------------> Frontend EC2 SG (Port 80 strictly from ALB SG)
3. Frontend EC2 SG ----> Backend EC2 SG (Port 8080 strictly from Frontend EC2 SG; Zero SSH)
4. Backend EC2 SG -----> RDS Database SG (Port 5432 strictly from Backend EC2 SG)
5. Outbound Egress ----> Private Subnets route to NAT Gateway in Public Subnet 2
```

---

## 3. Detailed Component Specifications

### 3.1 Network Tier (`modules/network`)
- **VPC:** `10.0.0.0/16`, DNS hostnames & support enabled.
- **Subnets:**
  - `public_subnet_cidrs = ["10.0.1.0/24", "10.0.16.0/24"]`
  - `app_private_subnet_cidrs = ["10.0.24.0/24", "10.0.48.0/24"]`
  - `db_private_subnet_cidrs = ["10.0.64.0/24", "10.0.96.0/24"]`
  - Availability Zones: `["us-east-1a", "us-east-1b"]`
- **Gateways:**
  - 1x Internet Gateway (`igw-${var.environment}`)
  - 1x Elastic IP + NAT Gateway (`nat-gateway-${var.environment}`) placed in `public_subnets[1]` (`10.0.16.0/24`, matching architectural diagram)
- **Route Tables:**
  - Public Route Table: Routes `0.0.0.0/0` → IGW, associated with both public subnets.
  - Private Route Table: Routes `0.0.0.0/0` → NAT Gateway, associated with both App Private and DB Private subnets.

### 3.2 Compute & Scaling Tier (`modules/compute`)
- **Dynamic AMI:** `data "aws_ami" "amazon_linux_2023"` matching `al2023-ami-2023.*-x86_64` owned by Amazon.
- **IAM Instance Profile:** Attached IAM Role with `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore` for AWS Systems Manager Session Manager.
- **Security Groups:**
  - `alb-sg`: Allows inbound ports 80/443 from `0.0.0.0/0`.
  - `frontend-sg`: Allows inbound port 80 strictly from `alb-sg`. Egress to backend SG on port 8080 and to internet for OS updates.
  - `backend-sg`: Allows inbound port 8080 strictly from `frontend-sg`. Egress to DB SG on port 5432 and to NAT GW for OS updates/SSM.
- **Application Load Balancer:**
  - Public-facing, spans both public subnets.
  - Target Group (`frontend-tg-${var.environment}`): Target type `instance`, port 80, health check path `/`.
  - HTTP Listener on port 80 forwarding to the frontend target group.
- **Frontend Auto Scaling Group & Launch Template:**
  - Instance Type: Parameterized (`t3.micro` in Dev/UAT, `t3.small` in Prod).
  - IMDSv2 Enforced (`http_tokens = "required"`).
  - User Data: Configures web server displaying instance metadata (Hostname, AZ) and proxying API calls to backend.
  - ASG Target Group Attachment to ALB Target Group.
- **Backend Auto Scaling Group & Launch Template:**
  - Deployed across App Private Subnets (`10.0.24.0/24`, `10.0.48.0/24`).
  - Instance Type: Parameterized.
  - IMDSv2 Enforced.
  - User Data: Bootstraps application service listening on port 8080 connected to PostgreSQL.
  - Capacities parameterized per environment (Dev/UAT: min 1, desired 2, max 3; Prod: min 2, desired 4, max 6).

### 3.3 Database Tier (`modules/database`)
- **Engine:** Amazon RDS PostgreSQL `15.7`.
- **Subnet Group:** Spans DB Subnet 1 (`10.0.64.0/24`) and DB Subnet 2 (`10.0.96.0/24`).
- **Access & Exposure:** `publicly_accessible = false`. Ingress port 5432 restricted to `backend-sg`.
- **High Availability:** Parameterized `multi_az`:
  - `dev`: `false`
  - `uat`: `false`
  - `prod`: `true`
- **Storage:** gp3, 20GB (Dev/UAT), 50GB (Prod) with storage autoscaling enabled.
- **Backup & Retention:** 1 day (Dev/UAT), 7 days (Prod).

### 3.4 Remote Backend (`global/s3_backend`)
- **S3 Bucket:** `three-tier-tf-state-<account-id-or-unique-suffix>` with versioning enabled, AES-256 encryption, public access block, and `force_destroy = true`.
- **DynamoDB Table:** `three-tier-tf-locks` with partition key `LockID` (S) and `PAY_PER_REQUEST` billing mode.

### 3.5 Environments (`envs/dev`, `envs/uat`, `envs/prod`)
- Dedicated root configurations for each environment.
- Backend configuration pointing to `key = "<env>/terraform.tfstate"`.
- `terraform.tfvars.example` with non-sensitive placeholder configurations.
- `.gitignore` preventing commit of `.tfstate` files, `.terraform/` cache, and real `.tfvars`.

---

## 4. Verification & Testing Strategy

1. **Syntax & Lint Validation:** `terraform fmt -check` and `terraform validate` across `global/s3_backend` and all `envs/` directories.
2. **Execution Plan Validation:** Verify clean plan generation with `terraform plan` to confirm dependency resolution and module parameter passing.
3. **Security Audit:** Confirm absence of open port 22 (SSH), verify IMDSv2 requirement, and ensure RDS has zero public ingress.

# Three-Tier AWS Infrastructure as Code with Terraform - Design Specification

**Date:** 2026-10-21  
**Status:** Approved  
**Author:** DevOps Engineering Team  

---

## 1. Project Overview & Objectives

This specification defines the architectural overhaul and standardization of the **Three-Tier AWS Infrastructure as Code with Terraform** project. The target implementation transforms the current workspace into an enterprise-ready, cost-conscious, and secure cloud platform.

### Core Objectives:
1. **Elastic Compute Layer:** Replace static `aws_instance` resources with an `aws_launch_template` and `aws_autoscaling_group` connected to an Application Load Balancer.
2. **Dynamic AMI Lookup:** Eliminate region-locked hardcoded AMIs using `data "aws_ami" "amazon_linux_2023"`.
3. **Database Modernization & Cost Optimization:** Transition to **PostgreSQL 15.7** on Amazon RDS, with configurable `multi_az` (`false` in Dev/UAT for Free Tier compatibility, `true` in Prod for high availability).
4. **Zero-Trust Network & Port Hardening:** Remove public SSH (Port 22) exposure. Enforce AWS Systems Manager (SSM) Session Manager for secure instance administration.
5. **State Management & Concurrency Control:** Implement remote state storage via an S3 backend with AES-256 encryption, bucket versioning, public access blocks, and DynamoDB distributed state locking (`global/s3_backend`).
6. **Multi-Environment Isolation:** Implement a directory-per-environment model (`envs/dev`, `envs/uat`, `envs/prod`) with independent state files, dedicated variable definitions, and `.tfvars.example` templates.
7. **Code Quality & Bug Remediation:** Fix the invalid `aws ~> 6.0` provider declaration to `aws ~> 5.0`, remove committed credentials, establish `.gitignore`, and configure `.tflint.hcl`.

---

## 2. Architecture Diagram

```text
========================================================================================================
                                     AWS REGION (e.g., us-east-1)
========================================================================================================
                                                  |
                                       [ Internet Gateway (IGW) ]
                                                  |
  +-----------------------------------------------+-----------------------------------------------+
  |                                     VPC (10.0.0.0/16)                                         |
  |                                                                                               |
  |   +-----------------------------------------------+   +-----------------------------------+   |
  |   |              AVAILABILITY ZONE A              |   |        AVAILABILITY ZONE B        |   |
  |   |                                               |   |                                   |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   |  | Public Subnet A (10.0.1.0/24)           |  |   |  | Public Subnet B (10.0.2.0/24|  |   |
  |   |  | - Internet-facing ALB (Node A)          |  |   |  | - Internet-facing ALB (Node B)| |  |
  |   |  | - NAT Gateway                           |  |   |  |                             |  |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   |                      |                        |   |                |                  |   |
  |   |                      v                        |   |                v                  |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   |  | App Private Subnet A (10.0.11.0/24)     |  |   |  | App Private Subnet B (12/24)|  |   |
  |   |  | - Auto Scaling Group (EC2 Instances)    |  |   |  | - Auto Scaling Group (EC2)  |  |   |
  |   |  | - SSM Session Manager Managed (No SSH)  |  |   |  | - SSM Session Manager (No SSH)| |  |
  |   |  | - Outbound via NAT Gateway              |  |   |  | - Outbound via NAT Gateway  |  |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   |                      |                        |   |                |                  |   |
  |   |                      v                        |   |                v                  |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   |  | DB Private Subnet A (10.0.21.0/24)      |  |   |  | DB Private Subnet B (22/24) |  |   |
  |   |  | - Primary RDS PostgreSQL 15.7           |  |   |  | - Standby RDS (Multi-AZ in  |  |   |
  |   |  |   (Port 5432 from App SG only)          |  |   |  |   Prod only)                |  |   |
  |   |  +-----------------------------------------+  |   |  +-----------------------------+  |   |
  |   +-----------------------------------------------+   +-----------------------------------+   |
  |                                                                                               |
  +-----------------------------------------------------------------------------------------------+

TRAFFIC FLOW & SECURITY CHAIN:
1. Public Internet ----> ALB Security Group (HTTP:80, HTTPS:443 from 0.0.0.0/0)
2. ALB SG -------------> App EC2 Security Group (HTTP:80 strictly from ALB SG; NO port 22)
3. App EC2 SG ---------> RDS Security Group (PostgreSQL:5432 strictly from App EC2 SG)
4. Outbound Egress ----> Private Subnets to NAT Gateway (Package updates / SSM endpoints)
```

---

## 3. Detailed Component Specifications

### 3.1 Network Tier (`modules/network`)
- **VPC:** `10.0.0.0/16`, DNS hostnames & support enabled.
- **Subnets:**
  - 2x Public (`10.0.1.0/24`, `10.0.2.0/24`) with `map_public_ip_on_launch = true`.
  - 2x App Private (`10.0.11.0/24`, `10.0.12.0/24`) with `map_public_ip_on_launch = false`.
  - 2x Database Private (`10.0.21.0/24`, `10.0.22.0/24`) with `map_public_ip_on_launch = false`.
- **Gateways:** 1x Internet Gateway, 1x NAT Gateway (in Public Subnet 1) with dedicated Elastic IP.
- **Routing:** Public Route Table targeting IGW; Private Route Table targeting NAT Gateway.

### 3.2 Compute & Scaling Tier (`modules/compute`)
- **Dynamic AMI:** `data "aws_ami" "amazon_linux_2023"` matching `al2023-ami-2023.*-x86_64` owned by Amazon.
- **IAM Instance Profile:** Attached IAM Role with `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore` for AWS Systems Manager Session Manager.
- **Security Groups:**
  - `alb-sg`: Allows inbound ports 80/443 from `0.0.0.0/0`.
  - `app-sg`: Allows inbound port 80 strictly from `alb-sg`. Egress all to `0.0.0.0/0`.
- **Launch Template:**
  - Instance Type: Parameterized (`t3.micro` in Dev/UAT, `t3.small` in Prod).
  - IMDSv2 Enforced: `http_tokens = "required"`, `http_put_response_hop_limit = 1`.
  - Network Interfaces: Private subnet placement, `associate_public_ip_address = false`.
  - User Data: Bootstraps Apache (`httpd`) and serves a dynamic webpage displaying hostname and Availability Zone retrieved securely via IMDSv2 tokens.
- **Application Load Balancer:**
  - Internet-facing, deployed across public subnets.
  - HTTP Listener on port 80 forwarding to the target group.
  - Target Group with HTTP health checks (`/`, matcher `200`, interval 30s).
- **Auto Scaling Group:**
  - Deployed across App Private Subnets.
  - Target Group attachment with `ELB` health checks and 300s grace period.
  - Lifecycle hook `create_before_destroy = true`.

### 3.3 Database Tier (`modules/database`)
- **Engine:** RDS PostgreSQL `15.7`.
- **Subnet Group:** Spans both Database Private Subnets across 2 AZs.
- **Access & Exposure:** `publicly_accessible = false`. Ingress port 5432 restricted to `app-sg`.
- **High Availability:** Parameterized `multi_az`:
  - `dev`: `false`
  - `uat`: `false`
  - `prod`: `true`
- **Storage:** gp3, 20GB (Dev/UAT), 50GB (Prod).
- **Backup & Retention:** 1 day (Dev/UAT), 7 days (Prod).

### 3.4 Remote Backend (`global/s3_backend`)
- **S3 Bucket:** `three-tier-tf-state-<unique-suffix>` with versioning enabled, AES-256 encryption, public access block, and `force_destroy = true`.
- **DynamoDB Table:** `three-tier-tf-locks` with partition key `LockID` (S) and `PAY_PER_REQUEST` billing mode.

### 3.5 Environments (`envs/dev`, `envs/uat`, `envs/prod`)
Each environment operates independently with its own:
- `main.tf`: Declares provider, backend configuration (`key = "<env>/terraform.tfstate"`), and invokes `network`, `compute`, and `database` modules.
- `variables.tf`: Parameter declarations.
- `outputs.tf`: Exports VPC ID, ALB DNS Name, and RDS Endpoint.
- `terraform.tfvars.example`: Reference configuration with dummy secrets.
- `.gitignore`: Excludes active `.tfvars` and local state files.

---

## 4. Verification & Testing Strategy

1. **Syntax & Lint Validation:** Run `terraform fmt -check` and `terraform validate` across `global/s3_backend` and all `envs/` directories.
2. **Execution Plan Validation:** Verify clean plan generation with `terraform plan` to confirm dependency resolution and module parameter passing.
3. **Security Audit:** Confirm absence of open port 22 (SSH), verify IMDSv2 requirement, and ensure RDS has zero public ingress.

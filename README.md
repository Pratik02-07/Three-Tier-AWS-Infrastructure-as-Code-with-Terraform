# Three-Tier AWS Infrastructure as Code with Terraform

A production-ready, modular, and highly available three-tier cloud architecture provisioned on AWS using **Terraform** and the official **AWS Provider**.

---


## 🏗️ Architecture Overview

```text
========================================================================================================================
                                             AWS REGION (e.g., us-east-1)
========================================================================================================================
                                                     |
                                            [ Internet Gateway (IGW) ]
                                                     |
  +--------------------------------------------------+--------------------------------------------------+
  |                                        VPC (10.0.0.0/16)                                            |
  |                                                                                                     |
  |   +---------------------------------------------------+   +---------------------------------------------------+   |
  |   |              AVAILABILITY ZONE A                  |   |              AVAILABILITY ZONE B                  |   |
  |   |                                                   |   |                                                   |   |
  |   |  +---------------------------------------------+  |   |  +---------------------------------------------+  |   |
  |   |  | Public Subnet A (10.0.1.0/24)             |  |   |  | Public Subnet B (10.0.2.0/24)             |  |   |
  |   |  | - Internet-facing ALB (Node A)              |  |   |  | - Internet-facing ALB (Node B)              |  |   |
  |   |  | - NAT Gateway A                             |  |   |  |                                             |  |   |
  |   |  +---------------------------------------------+  |   |  +---------------------------------------------+  |   |
  |   |                         |                         |   |                         |                         |   |
  |   |                         v                         |   |                         v                         |   |
  |   |  +---------------------------------------------+  |   |  +---------------------------------------------+  |   |
  |   |  | App Private Subnet A (10.0.11.0/24)        |  |   |  | App Private Subnet B (10.0.12.0/24)        |  |   |
  |   |  | - Auto Scaling Group (EC2 Instances)        |  |   |  | - Auto Scaling Group (EC2 Instances)        |  |   |
  |   |  | - Route to NAT Gateway A for outbound traffic| |   |  | - Route to NAT Gateway A for outbound traffic| |   |
  |   |  +---------------------------------------------+  |   |  +---------------------------------------------+  |   |
  |   |                         |                         |   |                         |                         |   |
  |   |                         v                         |   |                         v                         |   |
  |   |  +---------------------------------------------+  |   |  +---------------------------------------------+  |   |
  |   |  | DB Private Subnet A (10.0.21.0/24)         |  |   |  | DB Private Subnet B (10.0.22.0/24)         |  |   |
  |   |  | - Primary RDS Instance                      |  |   |  | - Standby RDS (Multi-AZ)                    |  |   |
  |   |  +---------------------------------------------+  |   |  +---------------------------------------------+  |   |
  |   +---------------------------------------------------+   +---------------------------------------------------+   |
  |                                                                                                     |
  ========================================================================================================================

  SECURITY GROUPS & TRAFFIC FLOW:
  1. Internet Traffic ----> ALB Security Group (Allows Ports 80/443 from 0.0.0.0/0)
  2. ALB SG -----------> App EC2 Security Group (Allows Port 80/8080 ONLY from ALB SG)
  3. App EC2 SG ---------> RDS Security Group (Allows Port 5432 ONLY from App EC2 SG)
  4. Outbound Internet --> App EC2s via NAT Gateway (For updates/packages; NO inbound public access)
```

---

## 📁 Repository Structure

```text
.
├── global/
│   └── s3_backend/    # Remote state S3 bucket (encrypted/versioned) & DynamoDB lock table
├── modules/
│   ├── network/       # Custom VPC, Public/Private Subnets across 2 AZs, IGW, NAT Gateway, Route Tables
│   ├── compute/       # ALB, Target Group, Auto Scaling Group, Launch Template, Security Groups
│   └── database/      # RDS PostgreSQL instance, DB Subnet Group, DB SG (App SG ingress only)
├── envs/
│   ├── dev/           # Development environment configuration (Single NAT GW, single-AZ DB)
│   └── prod/          # Production environment configuration (Multi-AZ DB, scaled ASG)
├── .tflint.hcl        # Terraform linting rules configuration
├── README.md          # Project documentation, architecture overview & teardown guide
```

---

## 🔒 Key Architectural Principles

- **Zero Direct Database Exposure**: Database security group accepts ingress traffic **exclusively** from the application security group (`var.app_security_group_id`). Port 5432 is never exposed publicly.
- **Private Subnet Isolation**: EC2 app instances reside in private subnets with no public IPs, accessible only via the public-facing Application Load Balancer.
- **Egress-Only Internet Access**: NAT Gateway enables instances in private subnets to pull system updates securely without accepting inbound external connections.
- **State Locking & Concurrency Control**: Amazon S3 backend (versioned & AES-256 encrypted) with DynamoDB state locking to prevent race conditions during concurrent runs.

---

## 🚀 Quick Start Guide

### 1. Provision Remote Backend (Run Once)
```powershell
cd global/s3_backend
terraform init
terraform apply
```

### 2. Deploy Development Infrastructure
```powershell
cd ../../envs/dev
terraform init
terraform plan
terraform apply
```

---

## 💰 Cost Estimation (Free Tier Compatibility)

| Service | Free Tier Allowance | Estimated Monthly Cost | Notes |
|---|---|---|---|
| **EC2 (`t3.micro`)** | 750 hours/month free | ~$7.50/month per instance | Covered under 12-month AWS Free Tier |
| **RDS (`db.t3.micro`)** | 750 hours/month + 20GB storage free | ~$15.00/month | Single-AZ in `dev` is Free Tier eligible |
| **S3 & DynamoDB** | 5GB S3 + 25GB DynamoDB free | ~$0.00/month | State storage stays within free limits |
| **Application Load Balancer** | 750 hours/month free (new accounts) | ~$16.20/month | Free Tier eligible for first 12 months |
| **NAT Gateway** ⚠️ | **NOT COVERED BY FREE TIER** | **~$32.40/month** ($0.045/hr) | Running cost incurred while active |

> [!WARNING]
> **Billing Alert**: AWS **NAT Gateway** incurs an hourly charge (~$0.045/hr) even with zero data transfer. Always run `terraform destroy` when done experimenting.

---

## 🧹 Teardown Instructions

To completely destroy all cloud resources and prevent charges:

```powershell
# 1. Destroy Environment Resources
cd envs/dev
terraform destroy -auto-approve

# 2. Destroy Remote State Backend
cd ../../global/s3_backend
terraform destroy -auto-approve
```

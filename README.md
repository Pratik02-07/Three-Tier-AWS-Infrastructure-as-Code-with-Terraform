# Three-Tier AWS Infrastructure as Code with Terraform

A production-ready, highly available, and secure three-tier cloud architecture provisioned on AWS using **Terraform** and the official **AWS Provider**.

---

## 🏗️ Architecture Blueprint

![3-Tier Architecture Diagram](docs/images/image.png)


---

## 📁 Repository Structure

```text
.
├── global/
│   └── s3_backend/             # Standalone S3 remote state bucket (encrypted/versioned) & DynamoDB lock table
├── modules/
│   ├── network/                # VPC, Subnets (Public, App Priv, DB Priv), IGW, NAT GW, Route Tables
│   ├── compute/                # ALB, Launch Templates (AL2023, SSM Profile), Frontend ASG, Backend ASG, SGs
│   └── database/               # RDS PostgreSQL 15.7, DB Subnet Group, Restricted DB Security Group
├── envs/
│   ├── dev/                    # Development environment (Single-AZ DB, 1-3 ASG)
│   ├── uat/                    # User Acceptance Testing environment (Staging mirror)
│   └── prod/                   # Production environment (Multi-AZ DB, 2-6 ASG)
├── docs/
│   ├── images/image.png        # Architecture Blueprint
│   ├── superpowers/specs/      # Design Specifications
│   └── superpowers/plans/      # Step-by-Step Implementation Plans
├── .gitignore                  # Excludes *.tfstate, .terraform/, *.tfvars
└── .tflint.hcl                 # AWS Terraform linter configuration
```

---

## 🔒 Key Architectural & Security Principles

1. **Zero Open SSH (Port 22 Eliminated):**
   * EC2 instances attach an IAM role with `AmazonSSMManagedInstanceCore`.
   * Secure shell administration is performed via **AWS Systems Manager (SSM) Session Manager** directly from the AWS Console or AWS CLI (`aws ssm start-session --target <instance-id>`). No `.pem` keys or open inbound ports are required.
2. **Strict Security Group Chaining (Least Privilege):**
   * `Internet` → `ALB SG` (Ports 80/443).
   * `ALB SG` → `Frontend SG` (Port 80 only).
   * `Frontend SG` → `Backend SG` (Port 8080 only).
   * `Backend SG` → `Database SG` (Port 5432 only).
3. **IMDSv2 Enforced:**
   * Both Frontend and Backend Launch Templates mandate IMDSv2 (`http_tokens = "required"`), neutralizing SSRF attack vectors.
4. **Dynamic AMI Resolution:**
   * Uses `data "aws_ami" "amazon_linux_2023"` to always deploy the latest patched Amazon Linux 2023 release across any AWS region.
5. **State Locking & Blast Radius Isolation:**
   * Each environment operates with its own isolated S3 state key (`dev/terraform.tfstate`, `uat/terraform.tfstate`, `prod/terraform.tfstate`) and DynamoDB distributed state locking.

---

## 🚀 Quick Start Guide

### 1. Provision Remote State Backend (Run Once)
```powershell
cd global/s3_backend
terraform init
terraform apply
```

### 2. Deploy Infrastructure (e.g., Development)
```powershell
cd ../../envs/dev
cp terraform.tfvars.example terraform.tfvars
# Update terraform.tfvars with your database password
terraform init
terraform plan
terraform apply
```

---

## 💰 Cost Estimation (Free Tier Compatibility)

| Service | Free Tier Allowance | Dev / UAT Est. Cost | Prod Est. Cost | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **EC2 (`t3.micro`)** | 750 hrs/month | Free Tier eligible | Scaled (`t3.small`) | Covered in AWS 12-month free tier |
| **RDS (`db.t3.micro`)** | 750 hrs/month + 20GB | Free Tier eligible | ~$30/mo (`db.t3.small`, Multi-AZ) | Single-AZ in Dev/UAT saves cost |
| **S3 & DynamoDB** | 5GB S3 + 25GB DDB | $0.00 / month | $0.00 / month | Well within free tier limits |
| **ALB** | 750 hrs/month (new accts) | Free Tier eligible | ~$16.20 / month | Standard AWS ALB pricing |
| **NAT Gateway** ⚠️ | None | ~$32.40 / month | ~$32.40 / month | Charged hourly ($0.045/hr) |

> [!WARNING]
> **Cost Alert:** AWS NAT Gateway incurs an hourly charge even with zero traffic. Remember to run `terraform destroy` when done experimenting.

---

## 🧹 Teardown Runbook

To destroy cloud resources cleanly:

```powershell
# 1. Destroy environment resources
cd envs/dev
terraform destroy -auto-approve

# 2. Destroy remote backend (when completely decommissioning project)
cd ../../global/s3_backend
terraform destroy -auto-approve
```
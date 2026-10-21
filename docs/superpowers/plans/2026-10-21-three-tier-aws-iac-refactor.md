# Three-Tier AWS Infrastructure as Code with Terraform Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the project into an enterprise-ready, production-grade 3-tier AWS architecture with directory-per-environment isolation, S3+DynamoDB remote state locking, true dual-tier Auto Scaling Groups (Frontend Web ASG + Backend App ASG), PostgreSQL 15.7 RDS with configurable Multi-AZ, zero-trust SSM Session Manager administration, and complete repository hygiene.

**Architecture:** 
- Network: VPC with 6 subnets across 2 AZs (`us-east-1a`, `us-east-1b`) matching the visual diagram (`10.0.1.0/24`, `10.0.16.0/24` public; `10.0.24.0/24`, `10.0.48.0/24` app private; `10.0.64.0/24`, `10.0.96.0/24` db private), 1 IGW, 1 NAT GW.
- Compute: Public ALB forwarding to Frontend ASG (Port 80) across public subnets; Frontend ASG communicating with Backend ASG (Port 8080) in private subnets; dynamic AL2023 AMI lookup, IMDSv2 enforced, SSM IAM instance profile (zero open SSH).
- Database: RDS PostgreSQL 15.7 with configurable `multi_az` (`false` in Dev/UAT, `true` in Prod), port 5432 restricted to Backend SG only.
- State & Environments: S3 + DynamoDB locking in `global/s3_backend`, directory-per-environment (`envs/dev`, `envs/uat`, `envs/prod`).

**Tech Stack:** Terraform (>= 1.5.0), AWS Provider (~> 5.0), AWS VPC, ALB, Auto Scaling Groups, Launch Templates, Amazon Linux 2023, RDS PostgreSQL 15.7, AWS Systems Manager (SSM), S3, DynamoDB.

**Spec:** [docs/superpowers/specs/2026-10-21-three-tier-aws-iac-refactor-design.md](file:///e:/PRATIK/Coding/AWS-DevOps/Project/3-TIER%20ARCHITECTURE%20ON%20AWS%20(UAT%20ENV)/docs/superpowers/specs/2026-10-21-three-tier-aws-iac-refactor-design.md)

## Global Constraints

- AWS Provider version must be `~> 5.0` (never `~> 6.0`).
- No hardcoded AMI IDs; use `data "aws_ami" "amazon_linux_2023"`.
- No open Port 22 (SSH); instances must use AWS Systems Manager (SSM) Session Manager.
- IMDSv2 must be enforced on all launch templates (`http_tokens = "required"`).
- All `.tfvars` containing secrets must be excluded via `.gitignore`; only `.tfvars.example` is committed.
- All modules must declare explicit variable types, descriptions, and outputs.

---

### Task 1: Repository Hygiene & Remote Backend Setup

**Files:**
- Create: `.gitignore`
- Create: `.tflint.hcl`
- Create: `global/s3_backend/main.tf`
- Create: `global/s3_backend/variables.tf`
- Create: `global/s3_backend/outputs.tf`

**Interfaces:**
- Consumes: AWS Provider ~> 5.0
- Produces: S3 bucket `three-tier-tf-state-backend-*` (versioned, encrypted) and DynamoDB table `three-tier-tf-locks`

- [ ] **Step 1: Create `.gitignore` to prevent secret leaks and state tracking**
  - Ignore `.terraform/`, `*.tfstate`, `*.tfstate.*`, `*.tfvars`, except `*.tfvars.example`.
- [ ] **Step 2: Create `.tflint.hcl` for AWS rule linting**
  - Enable AWS ruleset for provider ~> 5.0.
- [ ] **Step 3: Implement `global/s3_backend` for remote state storage & DynamoDB locking**
  - Configure `aws_s3_bucket`, `aws_s3_bucket_versioning`, `aws_s3_bucket_server_side_encryption_configuration`, `aws_s3_bucket_public_access_block`, and `aws_dynamodb_table` (`LockID`).
- [ ] **Step 4: Verify syntax and formatting with `terraform fmt` and `terraform validate`**
- [ ] **Step 5: Commit Task 1 deliverables**

---

### Task 2: Network Module Implementation (`modules/network`)

**Files:**
- Create: `modules/network/main.tf`
- Create: `modules/network/variables.tf`
- Create: `modules/network/outputs.tf`

**Interfaces:**
- Consumes: `vpc_cidr`, `availability_zones`, `public_subnet_cidrs`, `app_private_subnet_cidrs`, `db_private_subnet_cidrs`, `environment`
- Produces: `vpc_id`, `public_subnet_ids`, `app_private_subnet_ids`, `db_private_subnet_ids`, `nat_gateway_id`

- [ ] **Step 1: Write `modules/network/variables.tf`**
  - Define variables with defaults matching the visual diagram:
    - VPC CIDR: `10.0.0.0/16`
    - Availability Zones: `["us-east-1a", "us-east-1b"]`
    - Public Subnets: `["10.0.1.0/24", "10.0.16.0/24"]`
    - App Private Subnets: `["10.0.24.0/24", "10.0.48.0/24"]`
    - DB Private Subnets: `["10.0.64.0/24", "10.0.96.0/24"]`
- [ ] **Step 2: Write `modules/network/main.tf`**
  - Implement VPC with DNS support & hostnames.
  - Implement 2 Public Subnets, 2 App Private Subnets, 2 DB Private Subnets.
  - Implement Internet Gateway and attach to VPC.
  - Implement Elastic IP and NAT Gateway placed in Public Subnet 2 (`10.0.16.0/24`, matching the diagram).
  - Implement Public Route Table (route `0.0.0.0/0` -> IGW) and associations.
  - Implement Private Route Table (route `0.0.0.0/0` -> NAT GW) and associate with App & DB private subnets.
- [ ] **Step 3: Write `modules/network/outputs.tf`**
  - Export VPC ID, Subnet IDs (public, app private, db private).
- [ ] **Step 4: Validate `modules/network` syntax with `terraform validate`**
- [ ] **Step 5: Commit Task 2 deliverables**

---

### Task 3: Compute Module Implementation (`modules/compute`)

**Files:**
- Create: `modules/compute/main.tf`
- Create: `modules/compute/variables.tf`
- Create: `modules/compute/outputs.tf`

**Interfaces:**
- Consumes: `vpc_id`, `public_subnet_ids`, `app_private_subnet_ids`, `instance_type`, `environment`, ASG sizing parameters
- Produces: `alb_dns_name`, `alb_security_group_id`, `frontend_security_group_id`, `backend_security_group_id`

- [ ] **Step 1: Write `modules/compute/variables.tf`**
  - Define variables for VPC ID, subnet IDs, instance types, ports (frontend 80, backend 8080), ASG capacities.
- [ ] **Step 2: Implement IAM Role & Instance Profile for AWS Systems Manager (SSM)**
  - Create IAM Role `aws_iam_role.ssm_role` with trust policy for `ec2.amazonaws.com`.
  - Attach `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore`.
  - Create `aws_iam_instance_profile.ssm_profile`.
- [ ] **Step 3: Implement Security Groups**
  - `alb-sg`: Inbound HTTP 80 / HTTPS 443 from `0.0.0.0/0`.
  - `frontend-sg`: Inbound HTTP 80 from `alb-sg`. Egress to backend on 8080 and to internet for updates. NO port 22 open.
  - `backend-sg`: Inbound Port 8080 from `frontend-sg`. Egress to DB on 5432 and to internet (NAT) for updates. NO port 22 open.
- [ ] **Step 4: Implement Application Load Balancer & Target Group**
  - Public ALB spanning public subnets.
  - Target Group for frontend (port 80, HTTP, `/` health check).
  - HTTP Listener on port 80 forwarding to frontend target group.
- [ ] **Step 5: Implement Dynamic AMI Lookup & Launch Templates**
  - Dynamic AMI lookup: `data "aws_ami" "amazon_linux_2023"`.
  - Frontend Launch Template: Enforces IMDSv2, attaches SSM profile, configures web server user data, attaches to `frontend-sg`.
  - Backend Launch Template: Enforces IMDSv2, attaches SSM profile, configures backend service user data (port 8080), attaches to `backend-sg`.
- [ ] **Step 6: Implement Auto Scaling Groups**
  - Frontend ASG: Spans public subnets, attached to ALB target group, ELB health checks.
  - Backend ASG: Spans private app subnets, EC2 health checks.
  - Lifecycle: `create_before_destroy = true`.
- [ ] **Step 7: Write `modules/compute/outputs.tf`**
  - Export ALB DNS name, ALB SG ID, Frontend SG ID, Backend SG ID.
- [ ] **Step 8: Validate `modules/compute` syntax**
- [ ] **Step 9: Commit Task 3 deliverables**

---

### Task 4: Database Module Implementation (`modules/database`)

**Files:**
- Create: `modules/database/main.tf`
- Create: `modules/database/variables.tf`
- Create: `modules/database/outputs.tf`

**Interfaces:**
- Consumes: `vpc_id`, `db_private_subnet_ids`, `backend_security_group_id`, credentials, `multi_az`, `environment`
- Produces: `db_instance_endpoint`, `db_instance_id`

- [ ] **Step 1: Write `modules/database/variables.tf`**
  - Parameters for engine (default `postgres`), version (`15.7`), instance class (`db.t3.micro`), storage (`20`), DB name, username, password (sensitive), `multi_az` (bool).
- [ ] **Step 2: Implement DB Subnet Group and Database Security Group**
  - DB Subnet Group spanning the 2 DB private subnets.
  - Security Group: Inbound port 5432 **strictly** from `var.backend_security_group_id`.
- [ ] **Step 3: Implement `aws_db_instance`**
  - Engine `postgres`, version `15.7`, `publicly_accessible = false`, `multi_az = var.multi_az`.
  - Storage autoscaling enabled (max 100 GB).
  - `skip_final_snapshot = true` for easy lab destruction.
- [ ] **Step 4: Write `modules/database/outputs.tf`**
  - Export endpoint, port, instance ID.
- [ ] **Step 5: Validate `modules/database` syntax**
- [ ] **Step 6: Commit Task 4 deliverables**

---

### Task 5: Multi-Environment Setup (`envs/dev`, `envs/uat`, `envs/prod`)

**Files:**
- Create: `envs/dev/main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`
- Create: `envs/uat/main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`
- Create: `envs/prod/main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`

**Interfaces:**
- Consumes: `modules/network`, `modules/compute`, `modules/database`
- Produces: Isolated cloud environments with distinct state keys:
  - `dev/terraform.tfstate` (Single-AZ DB, 1-3 ASG)
  - `uat/terraform.tfstate` (Single-AZ DB, 1-3 ASG)
  - `prod/terraform.tfstate` (Multi-AZ DB, 2-6 ASG)

- [ ] **Step 1: Implement `envs/dev`**
  - S3 backend targeting `dev/terraform.tfstate`.
  - Module wiring for network, compute, database.
  - Values: `multi_az = false`, instance class `db.t3.micro`, app instance `t3.micro`.
  - Create `terraform.tfvars.example`.
- [ ] **Step 2: Implement `envs/uat`**
  - S3 backend targeting `uat/terraform.tfstate`.
  - Matching UAT environment naming and configuration.
  - Create `terraform.tfvars.example`.
- [ ] **Step 3: Implement `envs/prod`**
  - S3 backend targeting `prod/terraform.tfstate`.
  - Values: `multi_az = true`, instance class `db.t3.small`, app instance `t3.small`, ASG 2-6.
  - Create `terraform.tfvars.example`.
- [ ] **Step 4: Validate all environment modules**
- [ ] **Step 5: Commit Task 5 deliverables**

---

### Task 6: Cleanup of Legacy Files & Comprehensive Documentation

**Files:**
- Delete: Obsolete legacy root files (`locals.tf`, legacy `main.tf`, `providers.tf`, `variables.tf`, `graph.dot`)
- Delete: Obsolete legacy uncoupled modules (`modules/ALB`, `modules/frontend_ec2`, `modules/backend_ec2`, `modules/RDS`, `modules/VPC`)
- Delete: Obsolete plaintext `.tfvars` in root `envs/`
- Create: `README.md` (Architecture diagram, component breakdown, cost guide, deployment & teardown runbook)

- [ ] **Step 1: Safely remove obsolete legacy files**
- [ ] **Step 2: Write production-grade `README.md`**
  - Document architecture, security model (SSM, IMDSv2, SG chaining), cost breakdown, step-by-step deploy & destroy commands.
- [ ] **Step 3: Commit Task 6 deliverables**

---

### Task 7: Full Verification & Linting

**Files:**
- Verify: All files across repository

- [ ] **Step 1: Run `terraform fmt -check -recursive` across repository**
- [ ] **Step 2: Run `terraform init -backend=false` and `terraform validate` on each environment**
- [ ] **Step 3: Verify git status is clean and secrets are not tracked**
- [ ] **Step 4: Final verification commit**

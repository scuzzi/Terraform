# Terraform Infrastructure as Code Labs

Hands-on labs from *Terraform: Up & Running* by Yevgeniy Brikman (3rd Edition), building a multi-environment AWS infrastructure using Terraform.

## Architecture Overview

This project deploys a web application stack across two environments (staging and production) with shared global infrastructure.

```
                    ┌─────────────────────────────┐
                    │       Global (shared)       │
                    │  S3 Bucket (state storage)  │
                    │  DynamoDB (state locking)   │
                    └──────────────┬──────────────┘
                                   │
                 ┌─────────────────┴─────────────────┐
                 │                                   │
        ┌────────▼────────┐                 ┌────────▼────────┐
        │     Staging     │                 │   Production    │
        │                 │                 │                 │
        │  MySQL (RDS)    │                 │  MySQL (RDS)    │
        │  Web Cluster:   │                 │  Web Cluster:   │
        │   - ALB         │                 │   - ALB         │
        │   - ASG (2 inst)│                 │   - ASG (2-10)  │
        │   - t2.micro    │                 │   - t2.small    │
        │                 │                 │   - Auto-scaling│
        └─────────────────┘                 └─────────────────┘
```

## Project Structure

```
states/
├── global/s3/                          # Shared S3 backend + DynamoDB lock table
├── modules/                            # Reusable modules
│   ├── data-storage/mysql/             #   MySQL RDS module
│   └── services/web-cluster-services/  #   Web cluster module (ASG + ALB)
├── stage/vpc/                          # Staging environment
│   ├── data-storage/mysql/             #   Stage MySQL instance
│   └── services/web-cluster-services/  #   Stage web cluster
└── prod/vpc/                           # Production environment
    ├── data-storage/mysql/             #   Prod MySQL instance
    └── services/web-cluster-services/  #   Prod web cluster + autoscaling schedules
```

## Key Concepts Demonstrated

- **Remote State Management** - S3 backend with DynamoDB locking for team collaboration
- **State Isolation** - Separate state files per environment and component
- **Reusable Modules** - DRY infrastructure with parameterized modules for MySQL and web clusters
- **Environment Parity** - Same modules, different configurations for stage vs prod
- **Cross-Stack References** - Web cluster reads database outputs via `terraform_remote_state`
- **Security Best Practices** - Sensitive variables, S3 encryption, public access blocking
- **Auto Scaling** - Production scales out during business hours, scales in at night

## Deployment Order

Infrastructure must be deployed in this order due to dependencies:

1. `global/s3` - Creates the S3 bucket and DynamoDB table (required by all other modules)
2. `stage/vpc/data-storage/mysql` - Creates the database (outputs address/port)
3. `stage/vpc/services/web-cluster-services` - Creates the web cluster (reads DB state)

Tear down in reverse order.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) installed
- AWS account with credentials configured (`aws configure`)
- An S3 bucket name that is globally unique (update bucket names if needed)

## Usage

```bash
# Initialize and deploy (example: staging database)
cd states/stage/vpc/data-storage/mysql
terraform init
terraform apply

# Destroy when done to avoid costs
terraform destroy
```

Database credentials are passed via variables at runtime:
```bash
terraform apply -var="db_username=admin" -var="db_password=yourpassword"
```

Or via environment variables:
```bash
export TF_VAR_db_username="admin"
export TF_VAR_db_password="yourpassword"
terraform apply
```

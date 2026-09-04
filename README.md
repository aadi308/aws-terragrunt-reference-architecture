# AWS Terragrunt Reference Architecture

[![Validate infrastructure](https://github.com/REPLACE_ME/aws-terragrunt-reference-architecture/actions/workflows/validate.yml/badge.svg)](https://github.com/REPLACE_ME/aws-terragrunt-reference-architecture/actions/workflows/validate.yml)

A sanitized, recruiter-oriented reference implementation for running a container workload on AWS with Terraform and Terragrunt. It demonstrates reusable modules, isolated environment state, private compute, encrypted logs, least-privilege IAM examples, and automated policy checks.

> This repository is an independent public reference implementation written from scratch. Its design is inspired by infrastructure patterns used in professional production work that reduced provisioning time by approximately 60%. That measured outcome belongs to the professional work; this demonstration has not itself produced or independently validated that metric.

## The deployment problem

Infrastructure repositories often begin with one environment and accumulate copied configuration as staging and production are added. The copies drift, security settings diverge, and a routine networking change must be repeated in several places. Meanwhile, application teams need a repeatable way to deploy containers without placing workloads directly on the public internet.

This project addresses that problem with:

- reusable Terraform modules for networking, security, compute, and monitoring;
- Terragrunt configuration inheritance for shared defaults;
- distinct state keys and CIDR ranges for dev, staging, and production;
- an internet-facing TLS load balancer with Fargate tasks in private subnets;
- validation and security gates that run before changes are merged.

This is a reference architecture, not a turnkey production platform. Replace every `REPLACE_ME` value and review the design against your organization's requirements before deployment.

## Architecture

```mermaid
flowchart TB
  Internet((Internet)) -->|HTTPS 443| ALB[Application Load Balancer]

  subgraph AWS[Isolated AWS account or account boundary]
    subgraph VPC[VPC across 2-3 Availability Zones]
      subgraph Public[Public subnets]
        ALB
        NAT[NAT Gateway per AZ]
      end
      IGW[Internet Gateway] --- Public
      ALB -->|HTTP 80, SG-to-SG only| ECS[ECS Fargate service]
      subgraph Private[Private subnets]
        ECS
      end
      ECS -->|TLS egress| NAT
      ECS --> LOGS[Encrypted CloudWatch logs]
      VPC --> FLOW[Encrypted VPC flow logs]
    end
    ECS --> METRICS[CloudWatch metrics, alarms, dashboard]
  end

  TG[Terragrunt: dev / staging / production] --> VPC
  CI[GitHub Actions validation] --> TG
```

Each environment creates its own VPC and component state. The sample uses one NAT gateway per Availability Zone for resilient private-subnet egress. NAT gateways are frequently the largest fixed cost in a small demo; see [Cost and lower-cost alternatives](#cost-and-lower-cost-alternatives).

## Why Terragrunt

Terraform modules describe reusable infrastructure. Terragrunt handles how those modules are assembled for each environment:

- `live/root.hcl` generates the AWS provider and encrypted remote-state configuration once.
- `live/_env/*.hcl` supplies component defaults, dependency wiring, and module sources once.
- each `environment.hcl` holds only values that genuinely differ, such as CIDRs, task count, retention, and deletion protection.
- leaf `terragrunt.hcl` files select root and component configuration without duplicating inputs.

This inheritance model reduces copy/paste while keeping environment differences visible in review. `path_relative_to_include()` produces a distinct remote-state key for every component. Separate VPC CIDRs and state paths prevent accidental cross-environment coupling. For stronger production isolation, deploy each environment to a separate AWS account and state bucket.

## Repository structure

```text
.
├── .github/workflows/validate.yml
├── live
│   ├── _env
│   │   ├── alb-security-group.hcl
│   │   ├── ecs.hcl
│   │   ├── monitoring.hcl
│   │   ├── network.hcl
│   │   └── service-security-group.hcl
│   ├── dev
│   │   ├── environment.hcl
│   │   └── us-east-1/{network,alb-security-group,service-security-group,ecs-service,monitoring}
│   ├── staging
│   │   ├── environment.hcl
│   │   └── us-east-1/{network,alb-security-group,service-security-group,ecs-service,monitoring}
│   ├── production
│   │   ├── environment.hcl
│   │   └── us-east-1/{network,alb-security-group,service-security-group,ecs-service,monitoring}
│   └── root.hcl
├── modules
│   ├── ecs-fargate
│   ├── monitoring
│   ├── network
│   └── security-group
├── .checkov.yml
├── .env.example
├── .gitignore
├── .tflint.hcl
├── LICENSE
├── Makefile
└── README.md
```

## Security defaults

- Fargate tasks have no public IP and run only in private subnets.
- The ALB accepts HTTPS and uses a modern TLS policy; an ACM certificate is required.
- The task security group accepts application traffic only from the ALB security group.
- Fargate has only TCP/443 egress for image pulls and AWS API calls.
- VPC flow logs and application logs use customer-managed KMS keys with rotation enabled.
- CloudWatch log retention is explicit.
- The ECS task role starts with no permissions. Add narrowly scoped application permissions only when required.
- The execution role can write only to the service's log group. The public demonstration image needs no private-registry permission; add narrowly scoped ECR pull permissions when moving to a private repository.
- The container root filesystem is read-only and ECS Exec is disabled.
- Terraform state, plans, variable files, credentials, keys, environment files, generated providers, and Terragrunt caches are ignored.
- No credentials are stored in code. Use IAM Identity Center, short-lived role credentials, or GitHub Actions OIDC.

Remote state can contain sensitive values even when outputs are marked `sensitive`. Create the state bucket and lock table separately with versioning, encryption, public-access blocking, restricted bucket policies, and recovery controls. This repository deliberately does not bootstrap its own backend to avoid a circular dependency.

## Prerequisites

- Terraform `>= 1.5.7, < 2.0`
- Terragrunt `0.99.x` or a compatible release
- AWS CLI v2 and authorized, short-lived credentials
- TFLint with the AWS ruleset
- Checkov
- Gitleaks
- an existing encrypted S3 state bucket and DynamoDB lock table
- an ACM certificate in the selected AWS region

No AWS account number, backend name, certificate, credential, or internal endpoint is included.

## Setup and validation

1. Export placeholder-derived configuration in your shell. Do not commit a populated `.env` file.

   ```bash
   export AWS_PROFILE="replace-me"
   export TF_STATE_BUCKET="replace-me-terraform-state-bucket"
   export TF_LOCK_TABLE="replace-me-terraform-lock-table"
   export TF_VAR_certificate_arn="arn:aws:acm:us-east-1:000000000000:certificate/replace-me"
   ```

2. Authenticate with short-lived AWS credentials and confirm the intended identity.

   ```bash
   aws sts get-caller-identity
   ```

3. Review `live/dev/environment.hcl`, especially CIDRs, Availability Zones, NAT gateways, task sizing, tags, and deletion protection.

4. Validate without deploying.

   ```bash
   make fmt-check
   make validate
   make lint
   make security
   make secrets
   ```

5. Preview one environment from its regional directory.

   ```bash
   cd live/dev/us-east-1
   terragrunt run --all plan
   ```

6. Apply only after reviewing the plan and estimated cost.

   ```bash
   terragrunt run --all apply
   ```

## CI validation

The pull-request workflow is read-only and requests only `contents: read`. It runs:

1. `terraform fmt -check -recursive` to catch Terraform formatting drift;
2. `terragrunt hcl fmt --check` to catch HCL formatting drift;
3. `terraform init -backend=false` and `terraform validate` for every reusable module;
4. TFLint with recommended Terraform rules and the AWS ruleset;
5. Checkov static security and compliance checks;
6. Gitleaks across Git history and the working tree.

Module validation avoids remote-state access and AWS authentication. A delivery pipeline should add plan jobs using GitHub OIDC, environment protection rules, manual production approval, and saved plan artifacts with restricted retention.

## Design decisions

| Decision | Rationale | Trade-off |
|---|---|---|
| Small, focused modules | Makes network, security, service, and monitoring responsibilities easy to inspect | More dependency wiring than a monolithic module |
| Component-level state | Limits blast radius and permits independent changes | Cross-component outputs require Terragrunt dependencies |
| Private Fargate tasks | Removes direct inbound exposure and host management | Requires NAT or VPC endpoints for image and API access |
| HTTPS-only ALB | Demonstrates secure ingress and certificate management | Requires a domain and ACM certificate |
| One NAT per AZ | Avoids cross-AZ dependency and improves resilience | Material hourly and data-processing cost |
| Empty application task role | Makes least privilege the starting point | Real applications must add explicit permissions |
| KMS-encrypted logs | Demonstrates encryption and key rotation | Adds KMS cost and policy-management responsibility |

## Cost and lower-cost alternatives

**Warning:** this design creates billable AWS resources. NAT gateways, an Application Load Balancer, Fargate tasks, CloudWatch ingestion and storage, and KMS keys incur charges even at low traffic. Production is configured for three NAT gateways and three tasks. Consult the current AWS Pricing Calculator for the deployment region before applying; prices change and this repository does not provide a quote.

For a temporary lab, choose a deliberate alternative:

- Set `enable_nat_gateway = false` and do not deploy ECS. This leaves isolated private subnets for network-only review at the lowest infrastructure cost.
- Replace public image pulls with private ECR and add interface endpoints for ECR API, ECR DKR, and CloudWatch Logs plus an S3 gateway endpoint. Compare endpoint hourly cost against NAT usage.
- Extend the network module with a single-NAT mode for non-production. It is cheaper but introduces a single-AZ dependency and possible cross-AZ data charges.
- Run static validation only. Local emulators do not prove the behavior of every managed AWS service.

The committed environments retain the resilient per-AZ pattern so the routing design is unambiguous. Change it consciously before applying a portfolio environment.

## Cleanup and destroy

Destroy in reverse dependency order. Production ALB deletion protection must first be set to `false`, applied, and reviewed.

```bash
cd live/dev/us-east-1
terragrunt run --all destroy
```

Afterward, verify that no load balancers, NAT gateways, elastic IPs, ECS tasks, CloudWatch log groups, dashboards, alarms, or customer-managed KMS keys remain. KMS keys enter a 30-day pending-deletion period. Remote state is intentionally retained; delete it only under your organization's retention and recovery policy.

## What recruiters should examine

- how root, component, and environment inheritance keep configuration DRY;
- how state paths, CIDR ranges, and dependency graphs isolate environments;
- how modules expose narrow inputs and outputs instead of embedding environment assumptions;
- how public ingress terminates at the ALB while workloads remain private;
- how IAM, security-group references, encryption, flow logs, and retention express security defaults;
- how CI combines formatting, semantic validation, linting, policy-as-code, and secret scanning;
- how cost, operational trade-offs, and production gaps are documented.

## Limitations and roadmap

This reference does not include backend bootstrapping, Route 53 records, WAF, ALB access-log storage, autoscaling, a private ECR repository, VPC endpoints, service discovery, tracing, application secrets, deployment promotion, disaster recovery, or a complete OIDC delivery role. The public demonstration image is pinned by tag; production should pin an approved image by digest and scan it continuously. Checkov suppressions next to the ALB document the intentionally omitted WAF and log archive rather than hiding those gaps.

Suggested next steps:

- add a dedicated bootstrap stack for hardened state storage and locking;
- add ECR, image scanning, digest promotion, and private VPC endpoints;
- add AWS WAF, ALB access logs, Route 53, and certificate automation;
- add target-tracking autoscaling and SNS or incident-management alarm routing;
- add Terraform tests and ephemeral integration environments;
- add GitHub OIDC roles with environment-specific plan/apply workflows and approvals;
- add multi-region recovery exercises and documented RTO/RPO targets.

## License

MIT. See [LICENSE](LICENSE).

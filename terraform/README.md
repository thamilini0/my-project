# Terraform — AWS Platform

Provisions VPC, EKS, ECR, RDS PostgreSQL, Secrets Manager secret for DB credentials, and optional GitHub Actions OIDC IAM role.

## Layout

- **Root** (`terraform/`): composes modules; use via `envs/production`.
- **modules/vpc**: Public/private subnets, NAT, EKS subnet tags.
- **modules/eks**: Managed node group, GitHub OIDC deploy role + EKS access entry.
- **modules/rds**: Private PostgreSQL 16, encrypted, SG limited to EKS nodes.
- **modules/ecr**: Scan-on-push, lifecycle policy.

## First apply

1. Configure remote backend (`backend.tf` from example).
2. Set `terraform.tfvars` (never commit passwords).
3. Run from `envs/production`:

```bash
terraform init
terraform apply
```

## Cost levers

- `single_nat_gateway = true` saves NAT hours (less HA).
- Smaller `eks_node_instance_types` and `db.t4g.micro` for dev.
- Tear down: `terraform destroy` (respect RDS `deletion_protection` in production).

## GitHub OIDC

Set `github_org` and `github_repo`. Output `github_actions_role_arn` becomes `AWS_ROLE_ARN` in GitHub Actions.

Ensure the GitHub OIDC provider exists once per AWS account (this module creates it when org/repo are set).

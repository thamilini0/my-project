# Node.js Microservice — Production DevOps Platform

End-to-end platform: containerized Node.js service on AWS EKS with RDS, Terraform IaC, GitHub Actions CI/CD, and ArgoCD GitOps.

## Architecture Overview

```mermaid
flowchart TB
    subgraph Dev["Developer Workflow"]
        GH[GitHub Repository]
        GHA[GitHub Actions]
    end

    subgraph AWS["AWS Account"]
        VPC[VPC - Public/Private Subnets]
        EKS[EKS Cluster]
        RDS[(RDS PostgreSQL)]
        ECR[Amazon ECR]
        NAT[NAT Gateway]
    end

    subgraph K8s["Kubernetes / GitOps"]
        Argo[Argo CD]
        App[order-service Deployment]
        SVC[Service / Ingress]
    end

    GH --> GHA
    GHA -->|lint, test, scan| GH
    GHA -->|build & push| ECR
    GHA -->|update manifest tag| GH
    Argo -->|sync| EKS
    App --> EKS
    App --> RDS
    ECR --> App
    VPC --> EKS
    VPC --> RDS
    NAT --> EKS
```

### Component Summary

| Layer | Technology | Purpose |
|-------|------------|---------|
| Application | Node.js 20 + Express | Sample `order-service` microservice |
| Container | Multi-stage Dockerfile | Minimal runtime image, non-root user |
| IaC | Terraform 1.5+ | VPC, EKS, RDS, ECR, IAM |
| CI | GitHub Actions | ESLint, Jest, Trivy, Docker build |
| CD / GitOps | Argo CD | Declarative sync from `deploy/` manifests |
| Secrets | AWS Secrets Manager + K8s External Secrets (optional) | DB credentials |

### Network Layout (Terraform)

- **VPC** `/16` with 3 AZs
- **Public subnets**: NAT gateways, optional load balancer tags
- **Private subnets**: EKS worker nodes, RDS
- **RDS**: PostgreSQL in private subnets, security group allows EKS node SG only

---

## Directory Tree

```
dvop/
├── README.md
├── .github/
│   └── workflows/
│       └── ci-cd.yaml
├── apps/
│   └── order-service/
│       ├── package.json
│       ├── package-lock.json
│       ├── .dockerignore
│       ├── Dockerfile
│       ├── eslint.config.js
│       ├── src/
│       │   ├── index.js
│       │   ├── app.js
│       │   ├── routes/
│       │   │   └── health.js
│       │   └── config.js
│       └── test/
│           └── health.test.js
├── deploy/
│   ├── argocd/
│   │   ├── application.yaml
│   │   └── project.yaml
│   └── kubernetes/
│       ├── base/
│       │   ├── kustomization.yaml
│       │   ├── namespace.yaml
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   ├── secret.yaml.example
│       │   ├── hpa.yaml
│       │   └── networkpolicy.yaml
│       └── overlays/
│           └── production/
│               ├── kustomization.yaml
│               └── patch-replicas.yaml
└── terraform/
    ├── README.md
    ├── versions.tf
    ├── providers.tf
    ├── variables.tf
    ├── outputs.tf
    ├── backend.tf.example
    ├── main.tf
    ├── envs/
    │   └── production/
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── terraform.tfvars.example
    │       └── outputs.tf
    └── modules/
        ├── vpc/
        ├── eks/
        ├── rds/
        └── ecr/
```

---

## Prerequisites

### Local tools

| Tool | Version (min) |
|------|----------------|
| Node.js | 20.x |
| Docker | 24+ |
| Terraform | 1.5+ |
| AWS CLI | 2.x |
| kubectl | 1.28+ |
| helm | 3.12+ (for Argo CD install) |

### AWS

- Account with permissions for VPC, EKS, RDS, ECR, IAM, EC2
- S3 bucket + DynamoDB table for Terraform remote state (recommended)
- IAM user or OIDC role for GitHub Actions

### GitHub

- Repository with Actions enabled
- Secrets (see below)

---

## Step-by-Step Setup

### 1. Bootstrap Terraform state (one-time)

```bash
aws s3 mb s3://YOUR-TF-STATE-BUCKET --region us-east-1
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Copy `terraform/backend.tf.example` to `terraform/backend.tf` and set bucket/key/region.

### 2. Configure and apply infrastructure

```bash
cd terraform/envs/production
cp terraform.tfvars.example terraform.tfvars
# Edit: project_name, region, db_password (or use Secrets Manager later)

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Save outputs: `eks_cluster_name`, `ecr_repository_url`, `rds_endpoint`.

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name $(terraform output -raw eks_cluster_name)
kubectl get nodes
```

### 4. Install Argo CD

```bash
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --set server.service.type=LoadBalancer
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Apply GitOps project and application (update `repoURL` in `deploy/argocd/application.yaml`):

```bash
kubectl apply -f deploy/argocd/project.yaml
kubectl apply -f deploy/argocd/application.yaml
```

### 5. Create Kubernetes secrets for the app

Do not commit real secrets. From `deploy/kubernetes/base/secret.yaml.example`:

```bash
kubectl create namespace order-service --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic order-service-db \
  --namespace order-service \
  --from-literal=DATABASE_URL="postgresql://user:pass@RDS_ENDPOINT:5432/orders"
```

Or use External Secrets Operator with AWS Secrets Manager.

### 6. Build and run locally

```bash
cd apps/order-service
npm ci
npm test
npm run lint
docker build -t order-service:local .
docker run --rm -p 3000:3000 -e NODE_ENV=development order-service:local
curl http://localhost:3000/health
```

### 7. GitHub Actions secrets and variables

**Repository secrets**

| Name | Description |
|------|-------------|
| `AWS_ROLE_ARN` | IAM role for OIDC (recommended) or omit if using access keys |
| `AWS_ACCESS_KEY_ID` | Only if not using OIDC |
| `AWS_SECRET_ACCESS_KEY` | Only if not using OIDC |
| `AWS_REGION` | e.g. `us-east-1` |

**Repository variables**

| Name | Example |
|------|---------|
| `ECR_REPOSITORY` | From Terraform output `ecr_repository_url` |
| `EKS_CLUSTER_NAME` | From Terraform output |
| `K8S_NAMESPACE` | `order-service` |
| `AWS_ACCOUNT_ID` | Your account ID |

Use Terraform output `github_actions_role_arn` as GitHub secret `AWS_ROLE_ARN` (OIDC).

Workflow updates `deploy/kubernetes/base/kustomization.yaml` image tag and commits, or use a dedicated `images` patch; Argo CD auto-syncs.

### 8. First deployment via CI

Push to `main`. Pipeline runs lint → test → Trivy → build → push ECR → deploy (kubectl or manifest bump).

Verify:

```bash
kubectl -n order-service get pods,svc,hpa
kubectl -n order-service logs -l app=order-service --tail=50
```

---

## Security Notes

- RDS has no public accessibility; credentials via secrets only
- EKS API endpoint: private + public access restricted in production (adjust `cluster_endpoint_public_access_cidrs`)
- Container runs as UID 10001, read-only root filesystem where possible
- Trivy scans image in CI; fail on CRITICAL (configurable)
- NetworkPolicy restricts ingress to namespace / ingress controller

---

## Operational Runbook (short)

- **Roll back**: revert Git commit of manifest tag; Argo CD syncs previous revision
- **Scale**: HPA on CPU 70%; or edit overlay replicas
- **DB migrations**: run Job or init container with migration tool (not included in sample app)

See `terraform/README.md` for module-specific variables and cost considerations.

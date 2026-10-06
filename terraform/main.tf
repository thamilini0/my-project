data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  azs                = local.azs
  single_nat_gateway = var.single_nat_gateway
}

module "eks" {
  source = "./modules/eks"

  project_name                         = var.project_name
  environment                          = var.environment
  vpc_id                               = module.vpc.vpc_id
  private_subnet_ids                   = module.vpc.private_subnet_ids
  cluster_version                      = var.eks_cluster_version
  node_instance_types                  = var.eks_node_instance_types
  node_desired_size                    = var.eks_node_desired_size
  node_min_size                        = var.eks_node_min_size
  node_max_size                        = var.eks_node_max_size
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  github_org                           = var.github_org
  github_repo                          = var.github_repo
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  service_name = "order-service"
}

module "rds" {
  source = "./modules/rds"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  allowed_security_groups = [module.eks.node_security_group_id]
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  instance_class         = var.db_instance_class
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}/${var.environment}/rds/order-service"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = module.rds.endpoint
    port     = module.rds.port
    dbname   = var.db_name
    engine   = "postgres"
  })
}

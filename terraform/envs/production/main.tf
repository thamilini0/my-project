module "platform" {
  source = "../.."

  aws_region   = var.aws_region
  project_name = var.project_name
  environment  = "production"

  vpc_cidr           = var.vpc_cidr
  single_nat_gateway = var.single_nat_gateway

  eks_cluster_version     = var.eks_cluster_version
  eks_node_instance_types = var.eks_node_instance_types
  eks_node_desired_size   = var.eks_node_desired_size
  eks_node_min_size       = var.eks_node_min_size
  eks_node_max_size       = var.eks_node_max_size

  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class

  github_org  = var.github_org
  github_repo = var.github_repo
}

output "vpc_id" {
  value = module.platform.vpc_id
}

output "eks_cluster_name" {
  value = module.platform.eks_cluster_name
}

output "ecr_repository_url" {
  value = module.platform.ecr_repository_url
}

output "github_actions_role_arn" {
  value = module.platform.github_actions_role_arn
}

output "rds_endpoint" {
  value     = module.platform.rds_endpoint
  sensitive = true
}

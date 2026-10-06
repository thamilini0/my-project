output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "rds_endpoint" {
  value     = module.rds.endpoint
  sensitive = true
}

output "github_actions_role_arn" {
  value = module.eks.github_actions_role_arn
}

output "rds_secret_arn" {
  value     = aws_secretsmanager_secret.db_credentials.arn
  sensitive = true
}

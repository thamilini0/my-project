output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "github_actions_role_arn" {
  value = try(aws_iam_role.github_actions[0].arn, "")
}

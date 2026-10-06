variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Short project name used in resource naming"
}

variable "environment" {
  type        = string
  description = "Environment label (production, staging)"
  default     = "production"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use one NAT GW to reduce cost in non-prod"
  default     = false
}

variable "eks_cluster_version" {
  type    = string
  default = "1.31"
}

variable "eks_node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "eks_node_desired_size" {
  type    = number
  default = 2
}

variable "eks_node_min_size" {
  type    = number
  default = 2
}

variable "eks_node_max_size" {
  type    = number
  default = 5
}

variable "db_name" {
  type    = string
  default = "orders"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "github_org" {
  type        = string
  description = "GitHub organization or user for OIDC trust"
  default     = ""
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name for OIDC trust"
  default     = ""
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach EKS public API"
  default     = ["0.0.0.0/0"]
}

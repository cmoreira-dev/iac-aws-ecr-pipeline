output "role_arn" {
  description = "ARN of the role assumed by GitHub Actions via OIDC — set as AWS_ROLE_ARN in GitHub Variables"
  value       = aws_iam_role.gha_ecr_push.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider (created by bootstrap, only looked up here)"
  value       = data.aws_iam_openid_connect_provider.github_actions.arn
}

output "ecr_products" {
  description = "Product prefixes configured with create-on-push"
  value       = var.ecr_products
}

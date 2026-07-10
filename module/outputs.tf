output "role_arn" {
  description = "ARN da role assumida pelo GitHub Actions via OIDC — usar como AWS_ROLE_ARN nas Variables do GitHub"
  value       = aws_iam_role.gha_ecr_push.arn
}

output "oidc_provider_arn" {
  description = "ARN do OIDC provider do GitHub Actions"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "ecr_products" {
  description = "Prefixos de produto configurados com create-on-push"
  value       = var.ecr_products
}
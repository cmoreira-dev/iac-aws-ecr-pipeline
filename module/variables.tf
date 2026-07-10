variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
}

variable "ecr_products" {
  description = "Prefixos de produto no ECR (pastas). Cada um vira um repository creation template com CREATE_ON_PUSH — componentes (api, ui, ...) sob o prefixo são criados automaticamente no primeiro push, sem passar por Terraform."
  type        = list(string)
}

variable "github_repos" {
  description = "Repos do GitHub (\"org/repo\") autorizados a assumir a role de push via OIDC, restritos à branch main."
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "Tag mutability aplicada aos repositórios criados via template"
  type        = string
  default     = "IMMUTABLE"
}

variable "lifecycle_untagged_expire_days" {
  description = "Dias até expirar imagens sem tag nos repositórios criados via template"
  type        = number
  default     = 14
}

variable "ecr_scan_type" {
  description = "Tipo de scan de vulnerabilidade do registro (\"BASIC\" ou \"ENHANCED\")"
  type        = string
  default     = "BASIC"
}

variable "github_oidc_thumbprint" {
  description = "Thumbprint do certificado do OIDC provider do GitHub Actions (token.actions.githubusercontent.com)"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "iam_role_name" {
  description = "Nome da IAM role assumida pelo GitHub Actions via OIDC"
  type        = string
  default     = "gha-cmoreira-dev-ecr-push"
}
variable "aws_region" {
  description = "AWS region where the resources will be created"
  type        = string
}

variable "ecr_products" {
  description = "Product prefixes in ECR (folders). Each one becomes a repository creation template with CREATE_ON_PUSH — components (api, ui, ...) under the prefix are created automatically on first push, without going through Terraform."
  type        = list(string)
}

variable "github_repos" {
  description = "GitHub repos (\"org/repo\") authorized to assume the push role via OIDC, restricted to the main branch."
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "Tag mutability applied to repositories created via template"
  type        = string
  default     = "IMMUTABLE"
}

variable "lifecycle_untagged_expire_days" {
  description = "Days until untagged images expire in repositories created via template"
  type        = number
  default     = 14
}

variable "ecr_scan_type" {
  description = "Registry vulnerability scan type (\"BASIC\" or \"ENHANCED\")"
  type        = string
  default     = "BASIC"
}

variable "iam_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions via OIDC"
  type        = string
  default     = "gha-cmoreira-dev-ecr-push"
}

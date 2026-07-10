resource "aws_ecr_repository_creation_template" "product" {
  for_each = toset(var.ecr_products)

  prefix               = each.value
  description          = "Create-on-push pro produto ${each.value}"
  image_tag_mutability = var.image_tag_mutability
  applied_for          = ["CREATE_ON_PUSH"]

  encryption_configuration {
    encryption_type = "AES256"
  }

  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Expire untagged images after ${var.lifecycle_untagged_expire_days} days"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = var.lifecycle_untagged_expire_days
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = var.ecr_scan_type

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}
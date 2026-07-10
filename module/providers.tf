# terraform {
#   required_version = ">= 1.5.0"
#
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 6.28.0, < 7.0.0" # CREATE_ON_PUSH em ecr_repository_creation_template só existe a partir da 6.28.0
#     }
#   }
# }
#
# provider "aws" {
#   region = var.aws_region
# }
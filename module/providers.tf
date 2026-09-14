# terraform {
#   required_version = ">= 1.5.0"
#
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 6.28.0, < 7.0.0" # CREATE_ON_PUSH in ecr_repository_creation_template only exists from 6.28.0 onward
#     }
#   }
# }
#
# provider "aws" {
#   region = var.aws_region
# }
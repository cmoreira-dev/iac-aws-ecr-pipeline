# The GitHub Actions OIDC provider is created and owned OUT OF BAND by
# iac.homelab-live-infra/bootstrap/bootstrap.sh (only one per account is allowed,
# and it's shared with the IaC pipeline roles). This module just looks it up.
#
# Migration note: this used to be a `resource`. Before deploying this change,
# drop it from the ecr layer's state so Terraform doesn't try to destroy it:
#   cd aws/cmoreira-dev/us-east-1/ecr
#   terragrunt state rm 'aws_iam_openid_connect_provider.github_actions'
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

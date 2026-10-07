# The GitHub Actions OIDC provider is created and owned OUT OF BAND by
# <live-infra-repo>/bootstrap/bootstrap.sh (only one per account is allowed,
# and it's shared with the IaC pipeline roles). This module just looks it up.
#
# Migration note: this used to be a `resource`. Before deploying this change,
# drop it from the ecr layer's state so Terraform doesn't try to destroy it:
#   cd aws/<account>/<region>/ecr
#   terragrunt state rm 'aws_iam_openid_connect_provider.github_actions'
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

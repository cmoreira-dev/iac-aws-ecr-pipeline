# Só precisa existir uma vez por conta AWS. Se um provider pra
# token.actions.githubusercontent.com já existir (criado manualmente ou por
# outro módulo/stack), o apply vai falhar com EntityAlreadyExists — nesse
# caso, importar em vez de deixar este módulo criar um duplicado:
#   terraform import aws_iam_openid_connect_provider.github_actions \
#     arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_oidc_thumbprint]
}
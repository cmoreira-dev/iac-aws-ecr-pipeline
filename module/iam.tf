data "aws_iam_policy_document" "gha_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for repo in var.github_repos : "repo:${repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "gha_ecr_push" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.gha_trust.json
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:CreateRepository", # necessário pro create-on-push (ver Pendências no README)
    ]

    # wildcard por produto, não lista exata de repo — é assim que um
    # componente novo (ex: "padel-movement/worker") ganha permissão de push
    # sem precisar de nenhuma mudança neste módulo.
    resources = [
      for p in var.ecr_products :
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${p}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # exigido pela API do ECR, não dá pra restringir por recurso
  }
}

resource "aws_iam_role_policy" "gha_ecr_push" {
  name   = "ecr-push"
  role   = aws_iam_role.gha_ecr_push.id
  policy = data.aws_iam_policy_document.ecr_push.json
}
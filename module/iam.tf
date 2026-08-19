data "aws_iam_policy_document" "gha_trust" {
  statement {
    effect  = "Allow"
    actions = [
        "sts:AssumeRoleWithWebIdentity",
        "sts:TagSession",
        ]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # No ":sub" condition — GitHub's actual sub claim embeds immutable numeric org/repo
    # IDs (confirmed via CloudTrail: "repo:org@<org_id>/repo@<repo_id>:ref:refs/heads/
    # main", not the commonly-assumed "repo:org/repo:ref:refs/heads/main"), presumably
    # to stop a renamed/transferred repo from inheriting an old repo's trust. Matching
    # that would mean pinning per-repo numeric IDs here, which is extra fragile
    # complexity for no real security gain over ":ref" + ":repository" below (both use
    # plain, stable claim values — no IDs involved), which are sufficient on their own.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:ref"
      values   = ["refs/heads/main"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"
      values   = var.github_repos
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
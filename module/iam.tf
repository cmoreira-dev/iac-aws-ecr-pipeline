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

    # AWS hard-requires a trust policy on this provider to evaluate ":sub" or
    # ":job_workflow_ref" scoped to something other than "*" (rejects
    # UpdateAssumeRolePolicy otherwise, even with ":ref"/":repository" below already
    # doing the real restricting) — so ":sub" can't just be dropped. GitHub's actual sub
    # claim embeds immutable numeric org/repo IDs (confirmed via CloudTrail:
    # "repo:org@<org_id>/repo@<repo_id>:ref:refs/heads/main", not the commonly-assumed
    # "repo:org/repo:ref:refs/heads/main"), presumably to stop a renamed/transferred
    # repo from inheriting an old repo's trust — pinning those IDs here would be fragile
    # (they're not knowable from `var.github_repos` alone, and change if a repo is ever
    # recreated), so StringLike + wildcards over just the ID segments satisfies AWS's
    # requirement without depending on them.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for repo in var.github_repos :
        "repo:${split("/", repo)[0]}@*/${split("/", repo)[1]}@*:ref:refs/heads/main"
      ]
    }

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
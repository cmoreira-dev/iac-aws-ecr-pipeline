data "aws_iam_policy_document" "gha_trust" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:TagSession",
    ]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # AWS requires a `sub` (or `job_workflow_ref`) condition that isn't scoped to
    # a bare "*". This org does NOT use immutable identifiers — `sub` is the plain
    # documented form `repo:<owner>/<repo>:<context>` (verified from a live token
    # 2026-08-30; the earlier "@<id>" pattern here never matched). The real pins
    # are `repository` + `ref` below; `repo:<repo>:*` just satisfies AWS.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for repo in var.github_repos : "repo:${repo}:*"
      ]
    }

    # Optional tightening: also require the build go through the shared reusable
    # workflow. Enable once its job_workflow_ref format is confirmed for a
    # reusable-workflow call.
    # condition {
    #   test     = "StringLike"
    #   variable = "token.actions.githubusercontent.com:job_workflow_ref"
    #   values   = ["cmoreira-dev/.github/.github/workflows/build-push-ecr.yml@*"]
    # }

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
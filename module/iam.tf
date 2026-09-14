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

    # AWS requires a `sub` (or `job_workflow_ref`) condition not scoped to a bare
    # "*". The callers invoke this via a REUSABLE workflow
    # (cmoreira-dev/.github/.github/workflows/build-push-ecr.yml), and GitHub emits
    # the *immutable* `sub` form for reusable-workflow jobs — verified from a live
    # token 2026-08-30:
    #   repo:cmoreira-dev@<org_id>/api.ia.local-sara@<repo_id>:ref:refs/heads/main
    # The numeric IDs aren't knowable from var.github_repos, so wildcard them; the
    # real pins are `repository` + `ref` below.
    # (Direct, non-reusable workflows in this org get the plain
    # `repo:<owner>/<repo>:<context>` form — so a role assumed from a plain
    # workflow would need a different pattern.)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for repo in var.github_repos :
        "repo:${split("/", repo)[0]}@*/${split("/", repo)[1]}@*:ref:refs/heads/main"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = ["cmoreira-dev/.github/.github/workflows/build-push-ecr.yml@*"]
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
      "ecr:CreateRepository", # required for create-on-push (see Pending items in README)
    ]

    # wildcard per product, not an exact repo list — this is how a new
    # component (e.g. "padel-movement/worker") gets push permission without
    # needing any change to this module.
    resources = [
      for p in var.ecr_products :
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${p}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # required by the ECR API, can't be scoped to a resource
  }
}

resource "aws_iam_role_policy" "gha_ecr_push" {
  name   = "ecr-push"
  role   = aws_iam_role.gha_ecr_push.id
  policy = data.aws_iam_policy_document.ecr_push.json
}
# iac-aws-ecr-pipeline

Reusable Terraform module for the Docker image build & push pipeline to
AWS ECR via GitHub Actions, used by any product in the `cmoreira-dev` org —
not specific to one repo/product. Creates:

- An **ECR repository creation template** (`CREATE_ON_PUSH`) per product —
  components (`api`, `ui`, `worker`, ...) under a product are created
  automatically by AWS on first push, without needing an
  `aws_ecr_repository` per component.
- The registry's **scanning configuration** (scan on push, `BASIC` or
  `ENHANCED` level).
- The GitHub Actions **OIDC identity provider** (`token.actions.githubusercontent.com`).
- An **IAM role** assumable via OIDC by the GitHub repos listed in
  `github_repos`, with push permission scoped by product-prefix wildcard
  (includes `ecr:CreateRepository`, required for create-on-push).

Decision details (why OIDC instead of access keys, why create-on-push
instead of a repo per component, why not Crossplane) are in
`TODO-ecr-pipeline.md` at the root of the `cmoreira-dev` workspace.

## Requirements

`CREATE_ON_PUSH` in `aws_ecr_repository_creation_template` only exists from
the `hashicorp/aws` provider **v6.28.0** onward (it was
`PULL_THROUGH_CACHE`/`REPLICATION` before that) — the module already pins
this in `providers.tf` (`>= 6.28.0, < 7.0.0`). Validated with `tofu init` +
`tofu validate` (OpenTofu, compatible with the same HCL syntax).

## Usage

This module is meant to be consumed via Terragrunt from
`infra-as-code/iac.homelab-live-infra`, pointing `source` at this repo:

```hcl
# iac.homelab-live-infra/ecr-pipeline/terragrunt.hcl (example — not created yet)
include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "git::git@github.com:cmoreira-dev/iac-aws-ecr-pipeline.git//module?ref=main"
}

inputs = {
  ecr_products = ["padel-movement"]

  github_repos = [
    "cmoreira-dev/api.ia.padel-movement-analysis",
    "cmoreira-dev/ui.ia.padel-movement-analysis",
  ]
}
```

`aws_region` already comes from the `inputs` of live-infra's root
`terragrunt.hcl`.

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `aws_region` | yes | — | AWS region |
| `ecr_products` | yes | — | Product prefixes (folders) in ECR |
| `github_repos` | yes | — | `"org/repo"` repos authorized to assume the role, restricted to `main` |
| `image_tag_mutability` | no | `IMMUTABLE` | Tag mutability on repos created via template |
| `lifecycle_untagged_expire_days` | no | `14` | Expiration for untagged images |
| `ecr_scan_type` | no | `BASIC` | `BASIC` (Inspector Classic, free) or `ENHANCED` (Inspector v2, cost per image) |
| `github_oidc_thumbprint` | no | current GitHub thumbprint | Only change if GitHub rotates the certificate |
| `iam_role_name` | no | `gha-cmoreira-dev-ecr-push` | IAM role name |

## Outputs

| Name | Use |
|---|---|
| `role_arn` | Set as `AWS_ROLE_ARN` in Actions Variables (org level, if possible) |
| `oidc_provider_arn` | Reference, rarely needs to be consumed |
| `ecr_products` | Echo of the configured prefixes |

## Pending / things to validate before considering this done

- [ ] If a GitHub Actions OIDC provider already exists in the account
      (created manually or by another stack), import it instead of applying
      directly — see the comment in `module/oidc.tf`.
- [ ] Validate end-to-end that `ecr:CreateRepository` scoped by prefix
      wildcard is enough for `CREATE_ON_PUSH` to work — AWS's docs don't make
      it 100% explicit that this is the exact permission the pushing
      principal needs.
- [ ] Decide `BASIC` vs `ENHANCED` for `ecr_scan_type`.
- [ ] The build-only job on PRs (no push) and the release tag convention
      (`vX.Y.Z` vs. another scheme) are the responsibility of the GitHub
      Actions workflow, not this module — see `TODO-ecr-pipeline.md`.

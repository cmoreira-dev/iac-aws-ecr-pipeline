# iac-aws-ecr-pipeline

Módulo Terraform reutilizável pro pipeline de build & push de imagens Docker
pra AWS ECR via GitHub Actions, usado por qualquer produto da org
`cmoreira-dev` — não específico de um repo/produto. Cria:

- Um **ECR repository creation template** (`CREATE_ON_PUSH`) por produto —
  os componentes (`api`, `ui`, `worker`, ...) dentro de um produto são
  criados automaticamente pela AWS no primeiro push, sem precisar de um
  `aws_ecr_repository` por componente.
- A **scanning configuration** do registro (scan on push, nível `BASIC` ou
  `ENHANCED`).
- O **OIDC identity provider** do GitHub Actions (`token.actions.githubusercontent.com`).
- Uma **IAM role** assumível via OIDC pelos repos do GitHub listados em
  `github_repos`, com permissão de push escopada por wildcard de prefixo de
  produto (inclui `ecr:CreateRepository`, necessário pro create-on-push).

Detalhes de decisão (por que OIDC em vez de access keys, por que
create-on-push em vez de repo por componente, por que não Crossplane) estão
em `TODO-ecr-pipeline.md` na raiz do workspace `cmoreira-dev`.

## Requirements

`CREATE_ON_PUSH` em `aws_ecr_repository_creation_template` só existe a partir
do provider `hashicorp/aws` **v6.28.0** (era `PULL_THROUGH_CACHE`/`REPLICATION`
antes disso) — o módulo já pina isso em `providers.tf`
(`>= 6.28.0, < 7.0.0`). Validado com `tofu init` + `tofu validate`
(OpenTofu, compatível com a mesma sintaxe HCL).

## Uso

Este módulo é feito pra ser consumido via Terragrunt a partir de
`infra-as-code/iac.homelab-live-infra`, apontando `source` pra este repo:

```hcl
# iac.homelab-live-infra/ecr-pipeline/terragrunt.hcl (exemplo — ainda não criado)
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

`aws_region` já vem do `inputs` do `terragrunt.hcl` raiz do live-infra.

## Inputs

| Nome | Obrigatório | Default | Descrição |
|---|---|---|---|
| `aws_region` | sim | — | Região AWS |
| `ecr_products` | sim | — | Prefixos de produto (pastas) no ECR |
| `github_repos` | sim | — | Repos `"org/repo"` autorizados a assumir a role, restritos a `main` |
| `image_tag_mutability` | não | `IMMUTABLE` | Mutabilidade das tags nos repos criados via template |
| `lifecycle_untagged_expire_days` | não | `14` | Expiração de imagens sem tag |
| `ecr_scan_type` | não | `BASIC` | `BASIC` (Inspector Classic, grátis) ou `ENHANCED` (Inspector v2, custo por imagem) |
| `github_oidc_thumbprint` | não | thumbprint atual do GitHub | Só mudar se o GitHub rotacionar o certificado |
| `iam_role_name` | não | `gha-cmoreira-dev-ecr-push` | Nome da IAM role |

## Outputs

| Nome | Uso |
|---|---|
| `role_arn` | Setar como `AWS_ROLE_ARN` nas Actions Variables (nível de org, se possível) |
| `oidc_provider_arn` | Referência, raramente precisa ser consumido |
| `ecr_products` | Eco dos prefixos configurados |

## Pendências / coisas a validar antes de considerar isso pronto

- [ ] Se um OIDC provider do GitHub Actions já existir na conta (criado
      manualmente ou por outro stack), importar em vez de aplicar direto —
      ver comentário em `module/oidc.tf`.
- [ ] Validar de ponta a ponta que `ecr:CreateRepository` escopado por
      wildcard de prefixo é suficiente pro `CREATE_ON_PUSH` funcionar — a
      documentação da AWS não deixa 100% explícito que essa é a permissão
      exata que o principal que faz o push precisa.
- [ ] Decidir `BASIC` vs `ENHANCED` pro `ecr_scan_type`.
- [ ] O job de build-only em PRs (sem push) e a convenção de tag de release
      (`vX.Y.Z` vs outro esquema) são responsabilidade do workflow do GitHub
      Actions, não deste módulo — ver `TODO-ecr-pipeline.md`.

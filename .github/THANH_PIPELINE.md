# Thanh Infrastructure Pipeline

This pipeline manages only `environments/thanh`. The repository's deployment branch is `master`.

## Workflow

1. A pull request to `master` runs secret scanning, IaC policy scanning, formatting, offline validation, and an Azure-authenticated Terraform plan. The plan job runs only for pull requests from this repository; fork pull requests never receive Azure credentials.
2. A push to `master` runs the same CI checks and an authenticated Terraform plan.
3. A manual `plan` runs an authenticated plan without changing Azure.
4. A manual `apply` first runs the plan job, then waits at the protected `thanh` environment before re-planning and applying the same commit.
5. Only one Thanh CD run can execute at a time. Terraform state locking supplies an additional safety boundary.

Plan output, its SHA-256 checksum, Trivy IaC results, and deployment verification output are retained as GitHub Actions artifacts for 30 days. Binary Terraform plan files are intentionally not uploaded because they can contain sensitive values. Before apply, the workflow re-plans the approved commit and refuses to continue if the reviewable plan checksum has changed.

## GitHub Environments

Create these environments under **Settings > Environments**:

| Environment | Purpose | Protection |
| --- | --- | --- |
| `thanh-plan` | Azure-authenticated read and plan | No approval required |
| `thanh` | Infrastructure apply | Required reviewer, prevent self-review, allow only `master` |

Add these environment secrets to both environments:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `POSTGRESQL_ADMIN_PASSWORD`

The two environments can use different Azure client IDs. A mature least-privilege setup uses a read-oriented identity for `thanh-plan` and a deployment identity for `thanh`. Both identities need access to the remote state; the deployment identity also needs every Azure RBAC permission required by the Terraform resources and role assignments.

## Azure OIDC

Create one federated identity credential for each GitHub environment on the relevant Microsoft Entra application:

```text
repo:Dev-MT10-SI/infra:environment:thanh-plan
repo:Dev-MT10-SI/infra:environment:thanh
```

Use this issuer and audience:

```text
Issuer:   https://token.actions.githubusercontent.com
Audience: api://AzureADTokenExchange
```

No Azure client secret is required.

## VNN Agent Orchestrator ACR Image Push with OIDC

Terraform creates a dedicated user-assigned identity for
`Dev-MT10-SI/VNN-Agent-orchestrator`. Its federated credential accepts only
this subject:

```text
repo:Dev-MT10-SI@330316027/VNN-Agent-orchestrator@1374089373:ref:refs/heads/master
```

`Dev-MT10-SI/VNN-Agent-orchestrator` uses the
`AZURE_BUILD_CLIENT_ID` repository variable for this identity. Its value is
the `github_actions_acr_push_client_id` Terraform output. The existing
deployment workflow then requests an OIDC token and pushes images to ACR.
The subject contains immutable GitHub organization and repository IDs because
this repository uses a customized GitHub OIDC subject template.

The CI identity has `AcrPush` only at the ACR scope. AKS uses its separate
kubelet identity with `AcrPull`, and the ACR admin account remains disabled.

## Run A Plan

1. Open **Actions > Thanh Infrastructure CD > Run workflow**.
2. Select branch `master`.
3. Select `plan`.
4. Open the completed run to inspect the log, job summary, and `thanh-plan-*` artifact.

For an internal pull request, the **Plan Thanh pull request** check uploads the same reviewable plan evidence. Treat this check, **Secret and IaC policy checks**, and **Format and validate Thanh** as required status checks in the `master` ruleset.

A plan also runs automatically after relevant changes are pushed to `master`.

## Deploy

1. Open **Actions > Thanh Infrastructure CD > Run workflow**.
2. Select branch `master`.
3. Select `apply`.
4. Enter `apply-thanh` in the confirmation field.
5. Review the completed plan job and its artifact.
6. Approve the waiting `thanh` environment deployment.

The apply job checks out the same commit, re-runs the plan, verifies the plan checksum approved for the run, applies all enabled Thanh stacks in dependency order, and queries Azure to verify the resource group, AKS cluster, PostgreSQL servers, and deployed resources. A changed plan fails before apply and must be reviewed in a new run.

## Maintenance

GitHub Actions are pinned to immutable commit SHAs. Dependabot checks them weekly and opens update pull requests against `master`. Terraform and Terragrunt versions are declared at the top of both workflow files and should be upgraded through reviewed pull requests.

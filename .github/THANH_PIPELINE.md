# Thanh Infrastructure Pipeline

This pipeline manages only `environments/thanh`. The repository's deployment branch is `master`.

## Workflow

1. A pull request to `master` runs formatting and offline validation. It does not authenticate to Azure.
2. A push to `master` runs the same CI checks and an authenticated Terraform plan.
3. A manual `plan` runs an authenticated plan without changing Azure.
4. A manual `apply` first runs the plan job, then waits at the protected `thanh` environment before re-planning and applying the same commit.
5. Only one Thanh CD run can execute at a time. Terraform state locking supplies an additional safety boundary.

Plan output is uploaded as a text artifact for 14 days. Binary Terraform plan files are intentionally not uploaded because they can contain sensitive values.

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

## Run A Plan

1. Open **Actions > Thanh Infrastructure CD > Run workflow**.
2. Select branch `master`.
3. Select `plan`.
4. Open the completed run to inspect the log, job summary, and `thanh-plan-*` artifact.

A plan also runs automatically after relevant changes are pushed to `master`.

## Deploy

1. Open **Actions > Thanh Infrastructure CD > Run workflow**.
2. Select branch `master`.
3. Select `apply`.
4. Enter `apply-thanh` in the confirmation field.
5. Review the completed plan job and its artifact.
6. Approve the waiting `thanh` environment deployment.

The apply job checks out the same commit, re-runs the plan to detect changes that happened while approval was pending, applies all enabled Thanh stacks in dependency order, and queries Azure to verify the resource group, AKS cluster, PostgreSQL servers, and deployed resources.

## Maintenance

GitHub Actions are pinned to immutable commit SHAs. Dependabot checks them weekly and opens update pull requests against `master`. Terraform and Terragrunt versions are declared at the top of both workflow files and should be upgraded through reviewed pull requests.

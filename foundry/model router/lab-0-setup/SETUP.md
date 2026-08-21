# Lab 0 - Deploy the comparison models

> About 20 minutes. Prerequisites: PowerShell 7, Azure CLI, an existing Microsoft Foundry account and project, and permission to create model deployments.

You are here: **Lab 0** -> [Lab 1](../lab-1-live-evaluation/README.md) -> [Lab 2](../lab-2-hill-climbing/README.md)

## 1. Scenario

Northstar Devices needs a controlled experiment to determine whether routing can lower inference cost and latency without reducing policy compliance or account-security quality. Before measuring that hypothesis, every learner needs the same three-arm deployment shape and an environment file that records the deployment names.

## 2. What you will do

1. Authenticate to the correct Azure subscription.
2. Check that every requested model and version is available with `GlobalStandard` in the Foundry account region.
3. Deploy one fixed GPT baseline and two constrained Model Router deployments.
4. Read each deployment back and validate its provisioning state, model version, SKU, capacity, and routing subset.
5. Populate the shared ignored `.env` file.

## 3. Deploy

From the repository root:

```powershell
az login

.\lab-0-setup\deploy-models.ps1 `
    -SubscriptionId <subscription-id> `
    -ResourceGroup <resource-group> `
    -AccountName <foundry-account-name> `
    -ProjectEndpoint https://<account>.services.ai.azure.com/api/projects/<project>
```

The script uses Azure CLI management APIs and prompts before changing deployments. Add `-Confirm:$false` for a non-interactive workshop run after checking the displayed target. Use `-WhatIf` to preview operations.

## 4. Deployment profiles

| Arm | Default deployment | Selection |
|---|---|---|
| Fixed baseline | `baseline-gpt` | `gpt-5.4` version `2026-03-05` |
| GPT-family router | `router-gpt-family` | `BroadCurrent`: current non-legacy GPT-5 through GPT-5.6 models encoded in the script |
| Open-weight router | `router-open-weight` | `gpt-oss-120b`, `Llama-4-Maverick-17B-128E-Instruct-FP8`, and `DeepSeek-V3.2` |

Use `-GptFamilyProfile Gpt54Tier` or `-GptFamilyProfile Gpt5Tier` for a narrower same-generation router. The model names and versions are explicit for reproducibility. Review the current catalog, lifecycle status, quota, pricing, and licenses before a new workshop delivery.

The script creates or updates deployments and prints the validated readback result. It does not write deployment-manifest files or create the Foundry account, project, RBAC assignments, or quota.

## 5. Environment output

The script merges these values into the repository-root `.env` without replacing unrelated entries:

```dotenv
AZURE_AI_PROJECT_ENDPOINT=https://<account>.services.ai.azure.com/api/projects/<project>
BASELINE_GPT_DEPLOYMENT=baseline-gpt
GPT_FAMILY_ROUTER_DEPLOYMENT=router-gpt-family
OPEN_WEIGHT_ROUTER_DEPLOYMENT=router-open-weight
MODEL_ROUTER_DEPLOYMENT=router-open-weight
AZURE_TOKEN_CREDENTIALS=AzureCliCredential
```

`MODEL_ROUTER_DEPLOYMENT` is the active alias used by the Lab 1 notebook. The other variables preserve all three canonical arm names for Lab 2.

## 6. What you learned

1. A valid routing experiment starts with separate, versioned deployment arms.
2. Regional catalog checks and deployment readback prevent silent configuration drift.
3. Environment configuration can retain all three arms while selecting one active notebook target.

[Workshop home](../README.md) | Next: [Lab 1 - Live evaluation](../lab-1-live-evaluation/README.md)

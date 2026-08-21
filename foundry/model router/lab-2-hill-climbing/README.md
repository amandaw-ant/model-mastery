# Lab 2 - Complete the hill-climbing comparison

> About 60 minutes plus evaluation runtime. Prerequisites: [Lab 0](../lab-0-setup/SETUP.md) deployments and a representative, privacy-reviewed dataset.

You are here: [Lab 0](../lab-0-setup/SETUP.md) -> [Lab 1](../lab-1-live-evaluation/README.md) -> **Lab 2**

## 1. Scenario

Lab 1 qualifies one router against an operating envelope. This lab tests the business hypothesis directly: **can routing lower cost and latency without reducing policy compliance or account-security quality?** Establish a fixed-model baseline, test routing within the GPT family, then change only the eligible model family and test the open-weight router.

## 2. What you will compare

| Arm | Deployment | Model selection | What it proves |
|---|---|---|---|
| A | `baseline-gpt` | One directly deployed GPT model | Starting benchmark without routing |
| B | `router-gpt-family` | Model Router restricted to the recorded GPT-family allowlist | Whether routing improves on the fixed baseline |
| C | `router-open-weight` | Model Router restricted to `gpt-oss-120b`, `Llama-4-Maverick-17B-128E-Instruct-FP8`, and `DeepSeek-V3.2` | Whether changing the eligible family improves on Arm B |

Arms B and C retain Model Router intelligence. The intended lever between them is only the eligible model family. The alternatives are described as open-weight because their licenses differ; review each license and organizational policy before using the term open source.

## 3. Files

| File | Purpose |
|---|---|
| [02-three-arm-hill-climbing.ipynb](02-three-arm-hill-climbing.ipynb) | Live-only three-arm comparison notebook |
| `02-three-arm-hill-climbing.executed.ipynb` | Generated only after a complete successful live run; not currently checked in |
| `02-three-arm-hill-climbing.pdf` | Generated from that successful execution; not currently checked in |
| `model_router_artifacts/` | Ignored redacted CSV and manifest outputs from a successful run |

## 4. Validate the deployments

Use the deployment definitions in the Lab 0 script and its successful management-plane readback as the authoritative subset evidence. The script does not write manifest files. Send representative smoke prompts to both routers and inspect `response.model`:

- every GPT-family response must belong to the recorded GPT allowlist;
- every open-weight response must be one of the three configured alternatives;
- an out-of-subset response invalidates the comparison until configuration is corrected.

A model does not need to appear in a small smoke test for the manifest to be valid because routing depends on the prompts.

## 5. Run the smoke notebook and Auto Evaluation

Run the source notebook first to validate all three deployments with the 12 core and 8 challenge cases from Lab 1. It makes 60 billable requests and produces only smoke evidence.

Then use a representative governed dataset for the promotion comparison.

For the larger promotion evaluation, clone the [Microsoft Foundry Model Router Auto Evaluation toolkit](https://github.com/microsoft-foundry/Model-Router-Auto-Evaluation) as a separate repository and follow its current README. Do not expect its scripts or configuration files in this workshop repository.

The toolkit has its own environment contract. At the time this guide was validated, its core evaluation required `AZURE_MODEL_ROUTER_*`, `AZURE_OPENAI_*`, and `AZURE_JUDGE_*` endpoint, key, and deployment values. Its optional Foundry cloud post-processing uses `AZURE_AI_PROJECT_ENDPOINT`. Create the toolkit's `.env` from its own `.env.example`; do not overwrite this workshop's root `.env` or commit either file.

Run the same governed dataset twice with one independent judge deployment:

1. `router-gpt-family` versus `baseline-gpt`.
2. `router-open-weight` versus `baseline-gpt`.

Do not use a compared model or router as its own judge. Keep the baseline, judge, dataset, pricing snapshot, region, routing mode, concurrency, retries, content filters, and request ordering strategy unchanged.

The [core dataset](../lab-1-live-evaluation/router_eval.jsonl) and [challenge dataset](../lab-1-live-evaluation/router_eval_challenge.jsonl) satisfy the toolkit's required `id` and `prompt` fields. The built-in notebook combines all 20 cases automatically. To use the same combined smoke workload in a separately cloned toolkit, concatenate the files into that clone and validate them before making API calls:

```powershell
$WorkshopRoot = (Get-Location).Path
$ToolkitRoot = Join-Path $env:TEMP "Model-Router-Auto-Evaluation"

git clone https://github.com/microsoft-foundry/Model-Router-Auto-Evaluation.git $ToolkitRoot
Push-Location $ToolkitRoot
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e "."
Copy-Item .env.example .env

Get-Content `
	(Join-Path $WorkshopRoot "lab-1-live-evaluation\router_eval.jsonl"), `
	(Join-Path $WorkshopRoot "lab-1-live-evaluation\router_eval_challenge.jsonl") |
	Set-Content .\datasets\northstar_smoke.jsonl

# Edit this toolkit clone's .env and configs/default.yaml before a live run.
python scripts/run_eval.py --dataset .\datasets\northstar_smoke.jsonl --dry-run
```

Run `Pop-Location` when finished. If `$ToolkitRoot` already exists, update or reuse that clone instead of cloning over it. The toolkit README, `.env.example`, and `configs/default.yaml` remain authoritative because its interface can change independently of this workshop.

Use at least 100 representative prompts for a decision. Run once with the GPT-family router configured against the fixed baseline, preserve its results directory, then run again with the open-weight router against the same baseline. Compare the two preserved runs:

```powershell
python scripts/compare_results.py results\gpt-family-router results\open-weight-router
```

## 6. Decision gate

Report overall and by task:

- judge-scored quality and safety outcomes;
- input and output tokens plus price-aware cost from one dated pricing snapshot;
- p50 and p95 end-to-end latency;
- errors, retries, and selected-model distribution.

First determine whether Arm B improves on Arm A. Promote Arm C only if it passes the same quality and safety floors and improves the agreed cost, latency, or policy objective over Arm B. Otherwise retain the better previous arm, analyse failures by task and selected model, change one lever, and repeat.

The checked-in Lab 1 execution predates this complete three-arm experiment. It makes no baseline or winning-family claim.

## 7. What you learned

1. A router-versus-router comparison still needs a fixed-model baseline.
2. Deployment manifests, controlled variables, and an independent judge make results defensible.
3. Hill climbing promotes only changes that retain hard quality and safety constraints.

Previous: [Lab 1 - Live evaluation](../lab-1-live-evaluation/README.md) | [Workshop home](../README.md)

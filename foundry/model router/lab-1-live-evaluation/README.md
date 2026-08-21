# Lab 1 - Qualify one live Model Router candidate

> About 40 minutes. Prerequisite: [Lab 0](../lab-0-setup/SETUP.md) complete and the repository-root `.env` populated.

You are here: [Lab 0](../lab-0-setup/SETUP.md) -> **Lab 1** -> [Lab 2](../lab-2-hill-climbing/README.md)

## 1. Scenario

Northstar Devices has launched its Aurora X1 phone. A carrier disruption, duplicate-payment incident, and phishing campaign have pushed support demand beyond the team's fixed-model capacity. Support Operations wants to use Model Router to **lower inference cost and latency without reducing policy compliance or account-security quality**.

You own the model-selection policy. Before the router can enter the three-arm promotion experiment in Lab 2, you must answer a narrower question: **is this live router operationally credible enough to become a candidate?** You will test it with synthetic cases drawn from the launch incident and produce an auditable scorecard for the change review.

This is a smoke-test decision, not a production approval. The candidate must complete every request, classify every queue correctly, meet the local quality floor on at least 80% of cases, pass every high-risk case, and expose route, token, and latency evidence. Token usage is a cost proxy in this lab; a promotion decision must join dated model pricing. A larger governed evaluation is still required for promotion.

## 2. What you will do

1. Send a core workload and a harder challenge workload across classification, policy Q&A, summarisation, and constrained reasoning.
2. Capture the service-reported underlying model, token usage, latency, and response.
3. Calculate transparent reference-based quality indicators.
4. Evaluate the same captured responses with `azure-ai-evaluation`.
5. Apply the candidate smoke gates and export redacted evidence for review.

## 3. Files

| File | Purpose |
|---|---|
| [01-live-router-evaluation.ipynb](01-live-router-evaluation.ipynb) | Live-only source notebook |
| [router_eval.jsonl](router_eval.jsonl) | Twelve core launch-incident cases |
| [router_eval_challenge.jsonl](router_eval_challenge.jsonl) | Eight mixed-intent and high-risk challenge cases |

Both JSONL files retain `request_id` for the workshop notebooks and provide the equivalent `id` required by the external Model Router Auto Evaluation toolkit.

Running the source notebook makes 20 billable requests and can produce different routing, output, token, and latency results.

## 4. Run the notebook

From the repository root:

```powershell
uv venv .venv --python 3.13
.\.venv\Scripts\Activate.ps1
uv pip install --python .\.venv\Scripts\python.exe -r requirements.txt
.\.venv\Scripts\python.exe -m ipykernel install --user --name model-router-workshop --display-name "Python (.venv - Model Router Workshop)"
```

Select **Python (.venv - Model Router Workshop)** in VS Code, open the source notebook, and run all cells. To change the arm measured by this notebook, update `MODEL_ROUTER_DEPLOYMENT` in the root `.env` before starting the kernel.

There is no mock or offline execution path. Missing configuration, authentication, or live responses stop the run.

## 5. Interpret the evidence

Treat the 20 cases as a functional smoke test, not a benchmark. Passing means the router stayed inside the candidate operating envelope; it does not prove lower cost or latency than the fixed model. That claim requires the controlled baseline in Lab 2, dated pricing, repeated latency samples, calibrated policy and safety evaluation, and human review.

The final cell writes ignored artifacts under `model_router_artifacts/`. Prompt and response text are omitted from the redacted CSV.

## 6. What you learned

1. The optimization target is lower cost and latency without reducing policy compliance or account-security quality.
2. Core, challenge, and high-risk slices prevent averages from hiding important failures.
3. Token usage, latency, quality, and routing distribution must be read together.
4. A smoke-test pass qualifies a candidate for comparison; it does not justify promotion.

Previous: [Lab 0 - Setup](../lab-0-setup/SETUP.md) | [Workshop home](../README.md) | Next: [Lab 2 - Hill climbing](../lab-2-hill-climbing/README.md)

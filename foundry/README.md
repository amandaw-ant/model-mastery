# Building and Optimizing your AI Agents With Microsoft Foundry


A growing series of **self-guided technical workshops** that teach you how to ship production-grade AI applications on **Microsoft Foundry** — one model family at a time. Workshops target **L200–L400** learners (comfortable with Python, terminals, and cloud basics) and are designed for both live delivery and asynchronous self-paced study.

Each workshop is opinionated about the same end-to-end arc so the muscle memory transfers from one model family to the next:

| Phase | Description |
|-------|-------------|
| **Setup** | Provision a Foundry project, deploy the models the workshop needs, and verify your environment from GitHub Codespaces. |
| **Build** | Implement a realistic scenario (often an agent) using the model family's flagship capabilities through Foundry's SDKs. |
| **Explore** | Go deeper on the model family's specialised capabilities (embeddings, rerank, tool use, long context, vision, etc.) and connect them back to the scenario. |


## What's in a workshop folder

Every workshop follows the same top-level shape so you always know where to look:

```text
<model-family>/
├── README.md            # workshop overview — start here
├── sample.env           # canonical environment-variable reference
├── requirements.txt     # Python dependencies for the workshop
├── lab-0-setup/         # provisioning + env wiring (Codespaces-first)
├── lab-1-<scenario>/    # build a realistic application with the flagship model
└── lab-2-<deep-dive>/   # explore the model family's specialised capabilities
```

Open the workshop's `README.md` first — it links to `lab-0-setup/SETUP.md`, which walks you through provisioning in roughly 15–20 minutes.

> 📝 **Environment variables.** Every workshop ships a `sample.env` in its top-level folder that documents every variable the labs read (Foundry endpoint, deployment names, API keys, optional load-test knobs, etc.). Lab 0's `setup-env.sh` copies it to `.env` and fills in concrete values for you. Read `sample.env` first whenever you want to know what a workshop expects to find in its environment.

<br/>

## Prerequisites (common to all workshops)

- An Azure subscription with permission to create a Foundry account, project, and model deployments.
- GitHub Codespaces (recommended) or a local environment with Python 3.11+ and the Azure CLI.
- Familiarity with Jupyter notebooks and the Python ecosystem.

Each workshop's `lab-0-setup/SETUP.md` lists any model-family-specific extras (regions, quotas, SDK versions).

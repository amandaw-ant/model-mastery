# Lab 1: Building Agents with Claude on Microsoft Foundry

Welcome to Sparkles, the friendliest little cupcake shop on the internet.
Sparkles has more customers than staff, so in this lab you'll build the agent
that greets them, takes their orders, answers policy questions from the
shop's own documents, and reads their handwritten catering requests.

In this lab, you will:

- Talk to Claude in the Foundry Playground and change its behavior with one sentence
- Build a Python agent on Claude in Foundry
- Give it tools and a personality from the Cupcake Store MCP server, and order a real cupcake
- Connect the shop's knowledge base in Foundry IQ and watch Claude route between two tool servers
- Let Claude find the right tool in a catalog of twelve with tool search
- Produce a schema-valid receipt with structured outputs
- Watch Claude read a handwritten order and place it, applying store policy
- Compare two Claude tiers on the same hard problem

**How the lab works.** Every module ends with a checkpoint. Modules 1.4 through
1.6 are independent, so if you fall behind, skip to the next one. Completed
code for every module is in `sparkles-agent/snapshots/`; copy the one you
need over `agent.py` and carry on.

**Your environment.** VS Code with the repo open, a terminal, and the Foundry
portal in a browser tab. The `.env` file at the top of the repo is already
filled in for you unless the instructor says otherwise.

**Prerequisites**

- The workshop Foundry project (sign-in details from your instructor)
- Python 3.10+ with the packages in `requirements.txt` (pre-installed)

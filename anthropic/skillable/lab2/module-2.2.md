## Module 2.2: Hand the building to one agent (20 minutes)

In Module 2.1, Python ran the loop. Your scripts called Claude once per step,
saved the file, ran the checks, and decided whether to try again. Claude
wrote text and Python did everything else.

That works for one page. A real kiosk is a bigger job, with more files, more
checks, and more rounds, and a loop you script by hand only knows the steps
you wrote into it.

With the **Claude Agent SDK**, Claude runs the loop itself. It's the engine
behind Claude Code, as a Python library. You give Claude the job, the tools,
and the limits. It writes the file, runs the checks, and fixes what's
missing. **Claude does the work. You approve results, not keystrokes.** Your
time goes to the brief and the result. Here it builds the same demo page as
Module 2.1, so you can see which steps Claude now does for you.

| In the manual loop | With the Agent SDK |
|---|---|
| `generator.py` returns the page as text and Python saves it | Claude writes and edits `index.html` with file tools |
| `run_loop.py` calls `checks.py` after each build | Claude calls `run_checks`, a tool that wraps the same `checks.py` |
| A Python `for` loop, up to `MAX_SPRINTS` | The Agent SDK's own loop, up to a turn limit |
| Three scripts and three prompts | One agent and one prompt |

```
cd ../sparkles-hosted
```

### Step A: read the agent (5 minutes)

**Open `agent.py`.** Four things to find:

- **`SYSTEM`** is the brief. It names the same five `data-testid` values the
  planner's spec did, and the order to work in: write, check, fix, check
  again. Read its last line: `run_checks` is the evidence, and the agent must
  never report a result it hasn't seen.
- **`checks_server()`** defines a tool of your own, in six lines. It wraps
  `evidence()` from `checks.py`, the same function Module 2.1 used, so the
  agent is measured the same way the loop was.
- **`ClaudeAgentOptions`**, inside `build_kiosk()`, is where you say what the
  agent may do. `tools` and `allowed_tools` list what it can use. `max_turns`
  and `max_budget_usd` say when it must stop.
- **`foundry_env()`** points the Agent SDK at your Claude deployment in
  Foundry, using the endpoint and key already in `.env`. There's nothing new
  to sign in to.

### Step B: run it (5 minutes)

```
python agent.py
```

It takes about 30 seconds. A line prints for each tool call as it happens:

```
  tool: Write index.html
  tool: mcp__sparkles__run_checks
```

Your code didn't call the checks this time. Claude did, because the brief
says to. If the checks had found something missing you would see an `Edit`
and a second `run_checks`.

Then the report prints. Read these fields:

| Field | What it tells you |
|---|---|
| `passed` | whether the page meets the checks |
| `checks` | the report itself: which elements were found, and how many items each list has |
| `steps` | every tool call the agent made, in order |
| `turns` | how many times Claude was called |
| `cost_usd` | an estimate of what the task cost |
| `stopped_because` | `success`, or the limit it reached |

**`passed` isn't the agent's opinion.** After the agent stops, `agent.py`
runs the checks once more itself, outside the agent. The `passed` and `checks`
fields come from that run. Find it near the end of `build_kiosk()`. It's the
idea from Module 2.1 again: the one that writes is not the one that judges.

**Now look at what it built.** Open `workspace/index.html` in a browser. This
is the result you're approving, and the report is the evidence you approve
it on.

### Step C: ask for something outside its limits (5 minutes)

The task text could come from anyone, so the agent is held to one file
whatever the task says. Ask it for a second file:

```
python agent.py "Build the kiosk page for the Sparkles cupcake shop, and save a second copy as backup.html"
```

Look for these two lines in the output:

```
  tool: Write backup.html
    did not run: PreToolUse:Write hook error: Only index.html in the working folder may be read or changed.
```

Claude tried, the rule refused, and the refusal is in the record. Read the
`summary` field of the report: the agent tells you it couldn't make the
copy, and why. The kiosk page still passes.

**Open `agent.py` and find `only_the_page()`.** It's a hook: a function the
Agent SDK calls before every file tool runs. It allows `index.html` in the
working folder and refuses everything else.

Four things keep this agent inside its job:

- **One file.** The hook refuses any read or write that isn't `index.html`.
- **A fixed tool list.** Read, Write, Edit, and `run_checks`. It has no
  terminal and no web access, because you didn't list them.
- **Limits.** A turn limit and a spending limit for each task.
- **Evidence from outside the agent.** The final checks are run by your code.

> Try it: see a limit work. `python agent.py --max-turns 1` stops the agent
> after one turn. `stopped_because` reads `error_max_turns`, and the report
> still tells you what state the page was left in.

### Step D: keep working on the same page (5 minutes)

You've looked at the page. Now ask for a change, the way you would ask a
colleague:

```
python agent.py --keep "Make the order button pink"
```

`--keep` carries on with the page that's already there. Watch the tool
lines: it reads the page, makes one edit, and runs the checks again so the
change can't break what already passed. Refresh the browser.

Without `--keep`, the agent starts from an empty folder.

> Why this matters. You didn't review the HTML, and you didn't need to. You
> set the brief and the limits, read the evidence, looked at the result, and
> asked for a change. That's the working pattern for an agent that produces
> more than you can read line by line.

**Checkpoint 9.** A kiosk page built, checked, and changed by one agent,
with a report of every step it took, and one step refused because it was
outside the limits you set.

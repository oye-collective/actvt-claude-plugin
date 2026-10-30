---
name: actvt
description: Read live Mac metrics (CPU, GPU, memory, network, thermal), listening ports, and Claude Code, Codex, pi and Claude Desktop session history (cost, tokens, errors, plan limits, transcripts) from the Actvt macOS app. Use when the user asks what their agents cost or did, what an earlier session was about, whether the machine is under load, what is holding a port, or how much of their plan is left.
---

# Actvt

Actvt is a macOS menu-bar app that watches the Mac and the AI coding agents on it, and serves its
data as tools on a local MCP server. pi has no MCP client, so `actvt.sh` (next to this file) calls
those tools with curl. Everything stays on the Mac: the server listens on 127.0.0.1 only.

## Calling a tool

```sh
./actvt.sh list                                  # every tool, its arguments, what it returns
./actvt.sh agent_recent_activity '{"days":7}'    # one call; arguments are one JSON object
./actvt.sh system_metrics_snapshot               # tools without arguments need none
```

Run it from this skill's directory, or by its full path. It prints the tool's result (usually
JSON) and exits non-zero when the call fails, with the reason on the first line. Run `list` once
when you are unsure of a tool's arguments: the descriptions there are the reference.

## Which tool

| The user asks | Tool |
|---|---|
| What is the machine doing right now? | `system_metrics_snapshot`, or `system_cpu_current`, `system_gpu_current`, `system_memory_current`, `system_network_current`, `system_thermal_current` |
| How has load changed over the last hour or week? | `system_metrics_history` (`trailingMinutes`), `system_cpu_history`, `system_gpu_history` |
| What is listening on port N? | `ports_list` |
| What did my agents cost? | `agent_recent_activity` (per day), `agent_metrics_aggregate`, `agent_project_buckets` (per project) |
| How much of my plan is left? | `agent_usage_limits` |
| Find the session where... | `agent_search` (`text`), then `agent_session_summary` with its `compositeKey` |
| Pick up where a session left off | `agent_resume_session` (`compositeKey`, `tailTurns`) |
| Which sessions match a filter? | `agent_sessions_query`, with `agent_facet_options` for the models, branches and tools to filter on |
| What keeps failing? | `agent_error_patterns`, `agent_recent_error_count` |
| Was it the agent or the machine that stalled? | `session_machine_context` (`compositeKey`) |
| Sessions on my other machines | `agent_remote_sessions` |

## Two tools act instead of reading

- `port_kill` stops a process. Confirm with the user first, and pass the `expectedPort` or
  `expectedCommand` you saw in `ports_list`, so a pid reused by another process is refused.
- `agent_notify` puts a notification on the user's screen. Send one when you stop and need the
  user: a decision, a finished long run, or a task you gave up on. One per stop, never for
  progress. It returns `delivered: false` when the user has muted it; then say it in the chat.

Every other tool only reads.

## When it fails

- **`no MCP endpoint found`**: Actvt is not running, or its server is off. Ask the user to open
  Actvt and turn on Settings > MCP > Enable MCP server. If Actvt is not installed, it is at
  https://actvt.io (macOS 15.5 or later).
- **`did not answer`**: the app quit or the server was switched off after the endpoint was written.
  Ask the user to check that Actvt is running.
- **Not on a Mac**: Actvt's tools are only on the Mac where it runs. On another machine with
  `actvt-cli` installed, `actvt-cli sessions --json` and `actvt-cli transcript --json --id <id>`
  read that machine's sessions.

Actvt masks the PII it detects in session titles and turns when its masking setting is on.
`agent_resume_session` takes `forceMask: true` to mask even when it is off.

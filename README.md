# Actvt plugin for Claude Code

Connects Claude Code to [Actvt](https://actvt.io), a macOS menu bar app that monitors your Mac
and your AI coding agents. With this enabled, Claude can ask Actvt what is actually happening on
the machine it is running on, so questions like "was that slow because of the model or because
my Mac was throttling" have an answer.

## Requirements

macOS, with [Actvt](https://actvt.io) installed and its MCP server turned on in
**Settings > MCP**. This plugin is only a connector and ships no server of its own.

## Install

```sh
claude plugin marketplace add oye-collective/actvt-claude-plugin
claude plugin install actvt@actvt
```

> Already using Actvt? You may not need this. Actvt can register itself with your installed
> Claude Code and Codex CLIs from **Settings > MCP > Connected clients**, which is more reliable
> because it writes the live URL and token directly. This plugin is for people who prefer
> installing from the marketplace.

## Tools

25 tools in three groups.

- **System** reads live CPU, GPU, memory, network, thermal pressure and uptime, plus persisted
  history going back up to 30 days.
- **Ports** lists listening processes and can free a port. `port_kill` is the one mutating tool,
  annotated destructive so clients ask before running it, and it refuses protected, system and
  AI-agent processes.
- **Agent sessions** covers spend and token roll-ups, per-project breakdowns, transcript search,
  error patterns, remote sessions over SSH, and resume cues. These require a trial or Premium
  license. System and port tools work on the free tier.

## How the token works

Actvt binds loopback at `http://127.0.0.1:4096/mcp` behind a bearer token that is generated per
install and kept in the Keychain. While the server runs it mirrors the token to an owner-only
file at `~/Library/Application Support/ACTVT/mcp/endpoint.json`, and `scripts/actvt-auth.sh`
reads it at connection time. No token is stored in this repository.

If Actvt bound a port other than 4096 because it was taken, set `ACTVT_MCP_URL` before starting
Claude Code. Run `scripts/actvt-auth.sh` directly to diagnose a failed connection; it prints the
reason.

## License

This plugin, meaning the manifest, MCP config and helper script here, is MIT licensed. **The
Actvt application itself is closed source** and is distributed from [actvt.io](https://actvt.io).

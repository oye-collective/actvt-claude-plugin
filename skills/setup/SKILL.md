---
name: actvt-setup
description: Diagnose and fix the connection to Actvt's MCP server on macOS. Use when Actvt tools are unavailable, when /mcp shows actvt as failed, or when the user asks to set up or connect Actvt.
---

# Connecting Actvt

Actvt's MCP server runs inside the Actvt macOS app. It is not a standalone process, so it
only answers while the app is running with the server switched on. Work through these checks
in order and stop at the first one that fails.

## 1. Is Actvt installed?

```sh
ls -d /Applications/Actvt.app
```

If it is missing, the user needs to install Actvt from https://actvt.io. It is macOS only and
requires macOS 15.5 or later. Nothing else here will work until then.

## 2. Is the server switched on?

The endpoint descriptor only exists while the server is running.

```sh
ls -l ~/Library/Application\ Support/ACTVT/mcp/endpoint.json
```

If the file is missing, tell the user to open Actvt and turn on **Settings > MCP > Enable MCP
server**. This is a GUI toggle, so they have to do it. Once it is on, the file appears within a
second or two.

## 3. Which port did it bind?

```sh
plutil -extract url raw -o - ~/Library/Application\ Support/ACTVT/mcp/endpoint.json
```

Expect `http://127.0.0.1:4096/mcp`, which is what this plugin points at.

Actvt prefers 4096 but falls back to another port when something else already holds it. If the
URL shows a different port, the user should either free 4096 and restart Actvt, or export the
real endpoint before starting Claude Code:

```sh
export ACTVT_MCP_URL="$(plutil -extract url raw -o - ~/Library/Application\ Support/ACTVT/mcp/endpoint.json)"
```

## 4. Does the auth helper work?

```sh
"${CLAUDE_PLUGIN_ROOT}/scripts/actvt-auth.sh"
```

It should print a single JSON object containing an `Authorization` header. The script prints the
specific reason on failure, so read its output rather than guessing.

## 5. Does the server answer?

This isolates the server from Claude Code, so a failure here means the problem is Actvt rather
than the plugin.

```sh
TOKEN=$(plutil -extract token raw -o - ~/Library/Application\ Support/ACTVT/mcp/endpoint.json)
curl -s -X POST http://127.0.0.1:4096/mcp \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

A `401` means the token is stale, which the user can clear by toggling the MCP server off and on
in Settings. A refused connection means the server is not listening where the plugin expects.

## Notes worth knowing

- **Some tools are licence gated.** System and port tools work on the free tier. The `agent_*`
  session tools need an Actvt trial or Premium licence, so their absence is not a fault.
- **There is a built-in alternative.** Actvt can register itself directly from
  **Settings > MCP > Connected clients**, which writes the live URL and token into the user's
  CLI config. If this plugin keeps failing, that path avoids the fixed-port assumption entirely.
- **Everything stays local.** The server binds loopback only, and the descriptor file is owner
  readable. There is no hosted endpoint to fall back to, by design.

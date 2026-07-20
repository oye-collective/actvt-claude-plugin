#!/usr/bin/env bash
#
# Emits the Authorization header for Actvt's embedded MCP server.
#
# Actvt generates a bearer token per install, keeps it in the Keychain, and
# mirrors it (with the bound URL) to an owner-only descriptor file while the
# server is running. Reading it here means the token is never baked into this
# repository and never goes stale.
#
# Claude Code runs this on every connection and expects a JSON object of
# headers on stdout.

set -euo pipefail

ENDPOINT="${ACTVT_MCP_ENDPOINT_FILE:-$HOME/Library/Application Support/ACTVT/mcp/endpoint.json}"

die() {
  echo "actvt: $1" >&2
  exit 1
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "Actvt is a macOS app, so this plugin only works on macOS."
fi

if [[ ! -r "$ENDPOINT" ]]; then
  die "no MCP endpoint found at $ENDPOINT.
Open Actvt and turn on Settings > MCP > Enable MCP server. If Actvt is not
installed yet, get it at https://actvt.io"
fi

# plutil ships with macOS, so this avoids depending on python3 or jq.
TOKEN="$(plutil -extract token raw -o - "$ENDPOINT" 2>/dev/null || true)"

if [[ -z "$TOKEN" ]]; then
  die "the endpoint descriptor at $ENDPOINT has no token.
Toggle the MCP server off and on in Actvt's Settings > MCP to regenerate it."
fi

# The token is base64url (A-Z a-z 0-9 - _), so it needs no JSON escaping.
printf '{"Authorization": "Bearer %s"}\n' "$TOKEN"

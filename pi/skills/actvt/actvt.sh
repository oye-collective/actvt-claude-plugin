#!/usr/bin/env bash
#
# Calls a tool on Actvt's embedded MCP server and prints its result.
#
#   actvt.sh list                    the tools, with their arguments
#   actvt.sh <tool> ['<json args>']  one call, e.g. actvt.sh agent_recent_activity '{"days":7}'
#
# Actvt generates a bearer token per install, keeps it in the Keychain, and
# mirrors it (with the bound URL) to an owner-only descriptor file while the
# server is running. Reading it on every call means the token is never stored
# in this package and never goes stale.
#
# Everything used here ships with macOS: curl, plutil and osascript.

set -euo pipefail

ENDPOINT="${ACTVT_MCP_ENDPOINT_FILE:-$HOME/Library/Application Support/ACTVT/mcp/endpoint.json}"

die() {
  echo "actvt: $1" >&2
  exit 1
}

[[ $# -ge 1 ]] || die "usage: actvt.sh list | actvt.sh <tool> ['<json args>']"

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "Actvt is a macOS app, so its tools are only on the Mac. On this machine, use actvt-cli instead
(actvt-cli sessions --json, actvt-cli transcript --json --id <id>), if it is installed."
fi

if [[ ! -r "$ENDPOINT" ]]; then
  die "no MCP endpoint found at $ENDPOINT.
Open Actvt and turn on Settings > MCP > Enable MCP server. If Actvt is not
installed yet, get it at https://actvt.io"
fi

URL="$(plutil -extract url raw -o - "$ENDPOINT" 2>/dev/null || true)"
TOKEN="$(plutil -extract token raw -o - "$ENDPOINT" 2>/dev/null || true)"
[[ -n "$URL" && -n "$TOKEN" ]] || die "the endpoint descriptor at $ENDPOINT has no url or token.
Toggle the MCP server off and on in Actvt's Settings > MCP to regenerate it."

# JavaScript for Automation does the JSON work, so nothing needs installing.
# It reads small inputs from the environment and the response from stdin
# (a response can outgrow the environment), and prints plain text.
js() {
  osascript -l JavaScript -e "
    const env = \$.NSProcessInfo.processInfo.environment;
    const get = k => { const v = env.objectForKey(k); return v.isNil() ? '' : v.js; };
    const stdin = () => \$.NSString.alloc.initWithDataEncoding(
      \$.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile, \$.NSUTF8StringEncoding).js;
    $1"
}

if [[ "$1" == "list" ]]; then
  BODY='{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
else
  TOOL="$1"
  ARGS="${2:-}"
  [[ -n "$ARGS" ]] || ARGS='{}'
  BODY="$(TOOL="$TOOL" ARGS="$ARGS" js "
    let args;
    try { args = JSON.parse(get('ARGS')); } catch (e) { args = null; }
    args === null || typeof args !== 'object' || Array.isArray(args)
      ? 'BAD_ARGS'
      : JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'tools/call',
                         params: { name: get('TOOL'), arguments: args } });")"
  [[ "$BODY" != "BAD_ARGS" ]] || die "the arguments must be one JSON object, e.g. '{\"days\":7}'"
fi

# The header never appears on the command line: curl reads it from stdin.
RESPONSE="$(printf 'Authorization: Bearer %s\n' "$TOKEN" |
  curl -sS --max-time 60 -H @- -H 'Content-Type: application/json' -H 'Accept: application/json' \
    --data-binary "$BODY" "$URL")" ||
  die "Actvt did not answer at $URL. Check that the app is running and its MCP server is on."

OUT="$(printf '%s' "$RESPONSE" | js "
  const r = JSON.parse(stdin());
  if (r.error) {
    'error: ' + r.error.message;
  } else if (r.result.tools) {
    r.result.tools.map(t => {
      const s = t.inputSchema || {}, req = s.required || [];
      const args = Object.keys(s.properties || {}).map(k => req.includes(k) ? k + ' (required)' : k);
      return t.name + (args.length ? '  [' + args.join(', ') + ']' : '') + '\n    ' + t.description;
    }).join('\n');
  } else {
    (r.result.isError ? 'error: ' : '') +
      (r.result.content || []).filter(c => c.type === 'text').map(c => c.text).join('\n');
  }")"
printf '%s\n' "$OUT"
# A tool error or a protocol error is a failed call.
[[ "$OUT" != error:* ]]

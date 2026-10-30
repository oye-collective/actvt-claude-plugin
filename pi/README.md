# actvt-pi

[Actvt](https://actvt.io) for [pi](https://pi.dev): ask pi what your agents cost, what an earlier
session was about, whether the Mac is under load, or what is holding a port.

Actvt is a macOS menu-bar app that watches your Mac and your AI coding agents (Claude Code, Codex,
pi, Claude Desktop) and serves what it knows as tools on a local MCP server. pi has no MCP client,
so this package gives it a skill that calls those tools with curl. Nothing is sent anywhere: the
server listens on 127.0.0.1 only, and the package has no dependencies.

## Install

```sh
pi install npm:actvt-pi
```

Then, in Actvt, turn on **Settings > MCP > Enable MCP server**. Actvt needs macOS 15.5 or later.

## Use

Ask pi in plain words, or load the skill directly with `/skill:actvt`:

- "What did my agents cost this week?"
- "Find the session where I fixed the login bug and pick up where it left off."
- "How much of my Claude plan is left?"
- "What's listening on port 3000?"
- "Was that session slow because of the agent or because the Mac was busy?"

The skill's script also works on its own:

```sh
skills/actvt/actvt.sh list
skills/actvt/actvt.sh agent_recent_activity '{"days":7}'
```

It reads the server's address and token from the file Actvt writes while the server is on, on
every call, so the token is never stored in the package.

## License

MIT

#!/usr/bin/env bash
# Starts the Godot MCP server (stdio). The server drives a Godot executable: it uses GODOT_PATH when
# that is set, else this script looks for one (godot, godot4, ~/.local/bin/godot, or a copy in the
# agent-plugin cache). With none found the server still starts and its tools say Godot is missing.
set -u
GODOT_MCP_VERSION="${AGENT_PLUGIN_GODOT_MCP_VERSION:-0.1.1}"
if [ -z "${GODOT_PATH:-}" ]; then
  for c in godot godot4 "$HOME/.local/bin/godot" "${XDG_CACHE_HOME:-$HOME/.cache}/agent-plugin/godot/godot"; do
    p="$(command -v "$c" 2>/dev/null)" || continue
    if [ -x "$p" ]; then export GODOT_PATH="$p"; break; fi
  done
fi
[ -n "${GODOT_PATH:-}" ] || echo "godot-mcp: no Godot executable found; set GODOT_PATH=/path/to/godot" >&2
exec npx -y "@coding-solo/godot-mcp@${GODOT_MCP_VERSION}" "$@"

#!/usr/bin/env bash
# Starts the Godot MCP server (stdio): tugcantopaloglu/godot-mcp, pinned to one commit. Its npm
# package is far behind the repository, so the first start fetches that commit into the agent-plugin
# cache and builds it (npm ci); later starts reuse the build. The server drives a Godot executable:
# it uses GODOT_PATH when set, else this script looks for godot, godot4, ~/.local/bin/godot or a copy
# in the cache. With none found the server still starts and its tools say Godot is missing.
set -u
REPO="https://github.com/tugcantopaloglu/godot-mcp.git"
REF="${AGENT_PLUGIN_GODOT_MCP_REF:-88f0fbc69a08225d4fdec32f921209e127f52395}"
BASE="${XDG_CACHE_HOME:-$HOME/.cache}/agent-plugin"
DIR="$BASE/godot-mcp/$REF"

if [ -z "${GODOT_PATH:-}" ]; then
  for c in godot godot4 "$HOME/.local/bin/godot" "$BASE/godot/godot"; do
    p="$(command -v "$c" 2>/dev/null)" || continue
    if [ -x "$p" ]; then export GODOT_PATH="$p"; break; fi
  done
fi
[ -n "${GODOT_PATH:-}" ] || echo "godot-mcp: no Godot executable found; set GODOT_PATH=/path/to/godot" >&2

if [ ! -f "$DIR/build/index.js" ]; then
  echo "godot-mcp: first start, fetching and building ${REF:0:12} (about a minute; run /mcp to reconnect if this start times out)" >&2
  mkdir -p "$BASE/godot-mcp" || exit 1
  tmp="$(mktemp -d "$BASE/godot-mcp/build.XXXXXX")" || exit 1
  if ! { git init -q "$tmp" && git -C "$tmp" fetch -q --depth 1 "$REPO" "$REF" && git -C "$tmp" checkout -q FETCH_HEAD \
         && (cd "$tmp" && npm ci --no-audit --no-fund --loglevel=error \
             && { [ -f build/index.js ] || npm run build --loglevel=error; } && [ -f build/index.js ]); } >&2; then
    echo "godot-mcp: could not fetch or build $REPO at $REF" >&2
    rm -rf "$tmp"
    exit 1
  fi
  rm -rf "$DIR"
  mv "$tmp" "$DIR" || { rm -rf "$tmp"; exit 1; }
fi
exec node "$DIR/build/index.js" "$@"

#!/usr/bin/env bash
# Starts the Playwright MCP server (stdio). Uses a preinstalled Chromium when one exists
# (Claude Code cloud: /opt/pw-browsers/chromium); otherwise Playwright's own Chromium.
set -u
PW_MCP_VERSION="${AGENT_PLUGIN_PLAYWRIGHT_MCP_VERSION:-0.0.83}"
OUT="${XDG_CACHE_HOME:-$HOME/.cache}/agent-plugin/playwright-mcp"
mkdir -p "$OUT" 2>/dev/null
args=(--headless --isolated --browser chromium --output-dir "$OUT")
for c in "${AGENT_PLUGIN_CHROMIUM:-}" /opt/pw-browsers/chromium; do
  if [ -n "$c" ] && [ -x "$c" ]; then args+=(--executable-path "$c"); break; fi
done
# Chromium refuses to start as root without --no-sandbox (cloud containers run as root).
if [ "$(id -u)" = 0 ]; then args+=(--no-sandbox); fi
exec npx -y "@playwright/mcp@${PW_MCP_VERSION}" "${args[@]}" "$@"

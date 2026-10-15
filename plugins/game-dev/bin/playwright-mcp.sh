#!/usr/bin/env bash
# Starts the Playwright MCP server (stdio). Uses a preinstalled Chromium when one exists
# (Claude Code cloud: /opt/pw-browsers/chromium); otherwise Playwright's own browser.
set -u
PW_MCP_VERSION="${GAME_DEV_PLAYWRIGHT_MCP_VERSION:-0.0.83}"
args=(--headless --isolated)
for c in "${GAME_DEV_CHROMIUM:-}" /opt/pw-browsers/chromium; do
  if [ -n "$c" ] && [ -x "$c" ]; then args+=(--executable-path "$c"); break; fi
done
# Chromium refuses to start as root without --no-sandbox (cloud containers run as root).
if [ "$(id -u)" = 0 ]; then args+=(--no-sandbox); fi
exec npx -y "@playwright/mcp@${PW_MCP_VERSION}" "${args[@]}" "$@"

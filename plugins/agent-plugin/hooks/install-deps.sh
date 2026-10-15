#!/usr/bin/env bash
# Background installer started by ensure-deps.sh. Never fails the session; writes setup.done last.
set -u
echo $$ > "$STATE/setup.lock"
trap 'rm -f "$STATE/setup.lock"' EXIT
summary=""

if [ "${NEED_PY:-0}" = 1 ]; then
  pkgs=(pillow numpy "scipy>=1.11" "resvg-py>=0.5,<0.6")
  if python3 -m pip install -q "${pkgs[@]}" || python3 -m pip install -q --break-system-packages "${pkgs[@]}"; then
    summary="$summary python:ok"
  else summary="$summary python:FAILED"; fi
fi

if [ "${NEED_PW:-0}" = 1 ]; then
  deps=()
  if [ "$(id -u)" = 0 ] && command -v apt-get >/dev/null 2>&1; then deps=(--with-deps); fi
  if npx -y -p "@playwright/mcp@${AGENT_PLUGIN_PLAYWRIGHT_MCP_VERSION:-0.0.83}" playwright install "${deps[@]}" chromium; then
    summary="$summary playwright:ok"
  else summary="$summary playwright:FAILED"; fi
fi

for d in ${REPOS:-}; do
  echo "== install: $d"
  if (
    cd "$d" || exit 1
    if [ -f pnpm-lock.yaml ]; then
      corepack enable >/dev/null 2>&1 || npm i -g pnpm >/dev/null 2>&1
      pnpm install --frozen-lockfile || pnpm install
    elif [ -f yarn.lock ]; then
      corepack enable >/dev/null 2>&1; yarn install --frozen-lockfile || yarn install
    elif [ -f package-lock.json ]; then
      npm ci || npm install
    else
      npm install
    fi
  ); then summary="$summary $(basename "$d"):ok"; else summary="$summary $(basename "$d"):FAILED"; fi
done

echo "${summary# }" > "$STATE/setup.done"
echo "done:${summary}"

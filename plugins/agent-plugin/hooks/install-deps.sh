#!/usr/bin/env bash
# Background installer started by ensure-deps.sh with the repo paths as arguments.
# Never fails the session; writes setup.done last and releases the lock it holds.
set -u
echo $$ > "$LOCK/pid"
release() { [ "$(cat "$LOCK/pid" 2>/dev/null)" = "$$" ] && rm -rf "$LOCK"; }
trap release EXIT
trap 'exit 130' INT TERM HUP
rm -f "$STATE/setup.done"
summary=""

if [ "${NEED_PY:-0}" = 1 ]; then
  pkgs=(pillow numpy "scipy>=1.11" "resvg-py>=0.5,<0.6")
  if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
    python3 -m pip install -q "${pkgs[@]}" || python3 -m pip install -q --break-system-packages "${pkgs[@]}"
  else
    python3 -m pip install -q --user "${pkgs[@]}"
  fi && summary="$summary python:ok" || summary="$summary python:FAILED"
fi

if [ "${NEED_PW:-0}" = 1 ]; then
  deps=()
  if [ "$(id -u)" = 0 ] && command -v apt-get >/dev/null 2>&1; then deps=(--with-deps); fi
  if (cd / && npx -y -p "@playwright/mcp@${AGENT_PLUGIN_PLAYWRIGHT_MCP_VERSION:-0.0.83}" playwright install ${deps[@]+"${deps[@]}"} chromium); then
    summary="$summary playwright:ok"
  else summary="$summary playwright:FAILED"; fi
fi

pm_version() { grep -o "\"packageManager\"[[:space:]]*:[[:space:]]*\"$1@[^\"]*\"" package.json | grep -o "$1@[^\"+]*" | head -1; }
run_pm() { # run the repo's package manager without changing global shims
  local pm="$1"; shift
  if command -v corepack >/dev/null 2>&1; then corepack "$pm" "$@"
  elif command -v "$pm" >/dev/null 2>&1; then "$pm" "$@"
  else v="$(pm_version "$pm")"; npx -y "${v:-$pm}" "$@"; fi
}

for d in "$@"; do
  echo "== install: $d"
  key="$(printf '%s' "$d" | tr -c 'A-Za-z0-9._-' '_')"
  lockhash="$(cat "$d/package.json" "$d/pnpm-lock.yaml" "$d/yarn.lock" "$d/package-lock.json" 2>/dev/null | cksum | cut -d' ' -f1)"
  if (
    cd "$d" || exit 1
    if [ -f pnpm-lock.yaml ]; then run_pm pnpm install --frozen-lockfile
    elif [ -f yarn.lock ]; then run_pm yarn install --frozen-lockfile
    elif [ -f package-lock.json ]; then npm ci
    else npm install --no-package-lock
    fi
  ); then
    rm -f "$STATE/repos/$key.failed"; echo "$lockhash" > "$STATE/repos/$key.ok"; summary="$summary $(basename "$d"):ok"
  else
    echo "$lockhash" > "$STATE/repos/$key.failed"; summary="$summary $(basename "$d"):FAILED"
  fi
done

echo "${summary# }" > "$STATE/setup.done"
echo "done:${summary}"

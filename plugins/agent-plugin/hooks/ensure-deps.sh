#!/usr/bin/env bash
# agent-plugin SessionStart hook. Checks the tools the skills need. In Claude Code cloud sessions
# (CLAUDE_CODE_REMOTE=true, or AGENT_PLUGIN_AUTOINSTALL=1 anywhere) it installs what is missing in
# the background and returns at once; elsewhere it only prints what is missing.
set -u
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/agent-plugin"
mkdir -p "$STATE/repos" 2>/dev/null || exit 0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK="$STATE/setup.lock.d"

source_evt="startup"
if [ ! -t 0 ]; then
  input="$(cat 2>/dev/null || true)"
  s="$(printf '%s' "$input" | grep -o '"source"[[:space:]]*:[[:space:]]*"[a-z]*"' | grep -o '"[a-z]*"$' | tr -d '"')"
  [ -n "$s" ] && source_evt="$s"
fi

# AGENT_PLUGIN_PAID_OK=1 (set by the owner in the environment) pre-approves paid Agent Sprite Forge
# generation, capped per session: the caps go to Bash through CLAUDE_ENV_FILE. A cap set explicitly
# in the environment wins over AGENT_PLUGIN_PAID_MAX (default 20).
if [ "${AGENT_PLUGIN_PAID_OK:-}" = "1" ]; then
  cap="${AGENT_PLUGIN_PAID_MAX:-20}"
  case "$cap" in ''|*[!0-9]*) cap=20 ;; esac
  paid_cap="${FORGE_MAX_PAID_REQUESTS:-$cap}"
  cli_cap="${FORGE_SESSION_IMAGES:-$cap}"
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    printf 'export FORGE_MAX_PAID_REQUESTS=%s\nexport FORGE_SESSION_IMAGES=%s\n' "$paid_cap" "$cli_cap" >> "$CLAUDE_ENV_FILE" 2>/dev/null
  fi
  echo "agent-plugin policy: the owner pre-approved paid Agent Sprite Forge generation (AGENT_PLUGIN_PAID_OK=1). Run route_media.py / generate2dsprite / generate2dmap / video2dsprite without asking first, up to $paid_cap paid generations per session. FORGE_MAX_PAID_REQUESTS=$paid_cap and FORGE_SESSION_IMAGES=$cli_cap are exported for Bash; if a command's environment lacks them, set them on that command. When a cap stops a call, stop and ask the user before raising it. After each batch, say the route, the number of calls and the cost. PixelLab and any other paid image or video API still need the user's go-ahead before their first call of a session."
else
  echo "agent-plugin policy: a configured API key is not consent to spend. Before the first paid generation call of a session (Agent Sprite Forge route_media.py / generate2dsprite / generate2dmap / video2dsprite, PixelLab, any image or video API), tell the user the route, the number of calls and the estimated cost, and wait for their go-ahead."
fi

lock_pid() { cat "$LOCK/pid" 2>/dev/null; }
lock_alive() { [ -d "$LOCK" ] && p="$(lock_pid)" && [ -n "$p" ] && kill -0 "$p" 2>/dev/null; }

# An installer is still running: always say so, whatever triggered this hook.
if lock_alive; then
  echo "agent-plugin: background setup still running (log: $STATE/setup.log). Before running project tests or the sprite/map scripts, wait until $STATE/setup.done exists."
  exit 0
fi

# Only startup and resume may start an installer (clear/compact only report).
heavy=0
case "$source_evt" in startup|resume) heavy=1 ;; esac

need_py=0
(cd / && python3 -I -c 'import PIL, numpy, scipy, resvg_py') >/dev/null 2>&1 || need_py=1

need_pw=1
for c in "${AGENT_PLUGIN_CHROMIUM:-}" /opt/pw-browsers/chromium; do
  if [ -n "$c" ] && [ -x "$c" ]; then need_pw=0; break; fi
done
if [ "$need_pw" = 1 ]; then
  for dir in "${PLAYWRIGHT_BROWSERS_PATH:-}" "${XDG_CACHE_HOME:-$HOME/.cache}/ms-playwright" "$HOME/Library/Caches/ms-playwright"; do
    if [ -n "$dir" ] && ls -d "$dir"/chromium-* >/dev/null 2>&1; then need_pw=0; break; fi
  done
fi

cloud=0
if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || [ "${AGENT_PLUGIN_AUTOINSTALL:-}" = "1" ]; then cloud=1; fi

# Repos: install when node_modules is missing; a failed attempt is not retried until the lockfile changes.
repos=()
failed_repos=""
if [ "$cloud" = 1 ] && [ "${AGENT_PLUGIN_REPO_INSTALL:-1}" = "1" ]; then
  for d in "${AGENT_PLUGIN_REPOS_ROOT:-/home/user}"/*/; do
    d="${d%/}"
    [ -f "$d/package.json" ] || continue
    key="$(printf '%s' "$d" | tr -c 'A-Za-z0-9._-' '_')"
    lockhash="$(cat "$d/package.json" "$d/pnpm-lock.yaml" "$d/yarn.lock" "$d/package-lock.json" 2>/dev/null | cksum | cut -d' ' -f1)"
    if [ -f "$STATE/repos/$key.failed" ] && [ "$(cat "$STATE/repos/$key.failed")" = "$lockhash" ]; then
      failed_repos="$failed_repos $(basename "$d")"
      continue
    fi
    [ -d "$d/node_modules" ] && continue
    [ -f "$STATE/repos/$key.ok" ] && [ "$(cat "$STATE/repos/$key.ok")" = "$lockhash" ] && continue
    repos+=("$d")
  done
fi

if [ -n "$failed_repos" ]; then
  echo "agent-plugin: an earlier dependency install failed for:$failed_repos (log: $STATE/setup.log); it is not retried until the lockfile changes."
fi

if [ "$need_py" = 0 ] && [ "$need_pw" = 0 ] && [ "${#repos[@]}" = 0 ]; then exit 0; fi

if [ "$cloud" = 0 ]; then
  [ "$need_py" = 1 ] && echo "agent-plugin: Python packages for the sprite/map skills are missing: python3 -m pip install --user pillow numpy \"scipy>=1.11\" \"resvg-py>=0.5,<0.6\""
  [ "$need_pw" = 1 ] && echo "agent-plugin: no Playwright Chromium found; run: npx playwright install chromium"
  exit 0
fi

[ "$heavy" = 1 ] || exit 0

if [ "${AGENT_PLUGIN_DRYRUN:-}" = "1" ]; then
  echo "agent-plugin (dry run): python=$need_py playwright=$need_pw repos: ${repos[*]:-none}"
  exit 0
fi

# Take the lock atomically; clear a stale one left by a dead installer.
if ! mkdir "$LOCK" 2>/dev/null; then
  if lock_alive; then exit 0; fi
  rm -rf "$LOCK"
  mkdir "$LOCK" 2>/dev/null || exit 0
fi

launcher=(nohup)
command -v setsid >/dev/null 2>&1 && launcher+=(setsid)
NEED_PY="$need_py" NEED_PW="$need_pw" STATE="$STATE" LOCK="$LOCK" \
  "${launcher[@]}" bash "$HERE/install-deps.sh" ${repos[@]+"${repos[@]}"} >"$STATE/setup.log" 2>&1 </dev/null &
echo "$!" > "$LOCK/pid"

what=""
[ "$need_py" = 1 ] && what="$what Python packages,"
[ "$need_pw" = 1 ] && what="$what Playwright Chromium,"
[ "${#repos[@]}" -gt 0 ] && what="$what dependencies of: ${repos[*]},"
echo "agent-plugin: installing in the background:${what%,}. Log: $STATE/setup.log. Before running project tests or the sprite/map scripts, wait until $STATE/setup.done exists (it holds a summary)."
exit 0

#!/usr/bin/env bash
# agent-plugin SessionStart hook. Checks the tools the skills need; in Claude Code cloud sessions
# (CLAUDE_CODE_REMOTE=true, or AGENT_PLUGIN_AUTOINSTALL=1 anywhere) installs what is missing in the
# background and returns at once. On other machines it only prints what is missing.
set -u
STATE="${HOME}/.cache/agent-plugin"
mkdir -p "$STATE" 2>/dev/null || exit 0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

need_py=0
python3 -c 'import PIL, numpy, scipy, resvg_py' >/dev/null 2>&1 || need_py=1

need_pw=0
have_browser=0
for c in "${AGENT_PLUGIN_CHROMIUM:-}" /opt/pw-browsers/chromium; do
  if [ -n "$c" ] && [ -x "$c" ]; then have_browser=1; break; fi
done
if [ "$have_browser" = 0 ] && ! ls -d "$HOME"/.cache/ms-playwright/chromium-* >/dev/null 2>&1; then need_pw=1; fi

cloud=0
if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || [ "${AGENT_PLUGIN_AUTOINSTALL:-}" = "1" ]; then cloud=1; fi

repos=""
if [ "$cloud" = 1 ] && [ "${AGENT_PLUGIN_REPO_INSTALL:-1}" = "1" ]; then
  for d in "${AGENT_PLUGIN_REPOS_ROOT:-/home/user}"/*/; do
    d="${d%/}"
    if [ -f "$d/package.json" ] && [ ! -d "$d/node_modules" ]; then repos="$repos $d"; fi
  done
fi

if [ "$need_py" = 0 ] && [ "$need_pw" = 0 ] && [ -z "$repos" ]; then exit 0; fi

if [ "$cloud" = 0 ]; then
  [ "$need_py" = 1 ] && echo "agent-plugin: Python packages for the sprite/map skills are missing: python3 -m pip install pillow numpy \"scipy>=1.11\" \"resvg-py>=0.5,<0.6\""
  [ "$need_pw" = 1 ] && echo "agent-plugin: no Playwright Chromium found; the playwright MCP can install it with its browser_install tool."
  exit 0
fi

if [ -f "$STATE/setup.lock" ] && kill -0 "$(cat "$STATE/setup.lock" 2>/dev/null)" 2>/dev/null; then
  echo "agent-plugin: background setup already running (log: $STATE/setup.log). Before running project tests or the sprite/map scripts, wait until $STATE/setup.done exists."
  exit 0
fi

if [ "${AGENT_PLUGIN_DRYRUN:-}" = "1" ]; then
  echo "agent-plugin (dry run): python=$need_py playwright=$need_pw repos:${repos:- none}"
  exit 0
fi

rm -f "$STATE/setup.done"
NEED_PY="$need_py" NEED_PW="$need_pw" REPOS="$repos" STATE="$STATE" \
  nohup setsid bash "$HERE/install-deps.sh" >"$STATE/setup.log" 2>&1 </dev/null &
what=""
[ "$need_py" = 1 ] && what="$what Python packages,"
[ "$need_pw" = 1 ] && what="$what Playwright Chromium,"
[ -n "$repos" ] && what="$what dependencies of:$repos,"
echo "agent-plugin: installing in the background:${what%,}. Log: $STATE/setup.log. Before running project tests or the sprite/map scripts, wait until $STATE/setup.done exists (it holds a summary)."
exit 0

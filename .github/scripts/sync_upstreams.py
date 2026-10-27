#!/usr/bin/env python3
"""Pin every GitHub-sourced plugin in .claude-plugin/marketplace.json to the newest upstream commit
that touched its skills, and give the vendored Vite plugin a version derived from its upstream
commit when its files changed. claude.ai re-reads the marketplace when marketplace.json changes,
so a new pin or version is what carries an upstream update to it.

Usage: sync_upstreams.py [--vite-changed]   (GITHUB_TOKEN is used for the GitHub API when set)
"""
import json
import os
import posixpath
import sys
import urllib.parse
import urllib.request

MARKETPLACE = ".claude-plugin/marketplace.json"
VITE_COMMIT = "plugins/vite/UPSTREAM_COMMIT"


def latest_commit(repo, path):
    """The newest commit on the default branch of ``repo`` that touched ``path`` (all files if None)."""
    query = {"per_page": "1"}
    if path:
        query["path"] = path
    req = urllib.request.Request(f"https://api.github.com/repos/{repo}/commits?{urllib.parse.urlencode(query)}",
                                 headers={"Accept": "application/vnd.github+json"})
    if os.environ.get("GITHUB_TOKEN"):
        req.add_header("Authorization", f"Bearer {os.environ['GITHUB_TOKEN']}")
    with urllib.request.urlopen(req, timeout=30) as resp:
        commits = json.load(resp)
    if not commits:
        raise RuntimeError(f"{repo}: no commit found for path {path!r}")
    return commits[0]["sha"]


def skills_root(entry):
    """The deepest folder holding every skill the entry lists, or None for the whole repository."""
    paths = [posixpath.normpath(p.lstrip("./") or ".") for p in entry.get("skills", [])]
    if not paths:
        return None
    root = posixpath.commonpath(paths)
    return None if root in ("", ".") else root


def update(marketplace, vite_changed, fetch=latest_commit, vite_commit=None):
    """Apply the pins in place; return a list of human-readable changes."""
    changes = []
    for entry in marketplace["plugins"]:
        source = entry.get("source")
        if isinstance(source, dict) and source.get("source") == "github":
            sha = fetch(source["repo"], skills_root(entry))
            if source.get("sha") != sha:
                changes.append(f"{entry['name']}: {source['repo']} {sha[:12]}")
                source["sha"] = sha
        elif entry["name"] == "vite" and vite_changed and vite_commit:
            version = f"0.0.0-g{vite_commit[:12]}"
            if entry.get("version") != version:
                changes.append(f"vite: antfu/skills {vite_commit[:12]}")
                entry["version"] = version
    return changes


def main():
    with open(MARKETPLACE, encoding="utf-8") as f:
        marketplace = json.load(f)
    vite_commit = None
    if os.path.exists(VITE_COMMIT):
        with open(VITE_COMMIT, encoding="utf-8") as f:
            vite_commit = f.read().strip()
    changes = update(marketplace, "--vite-changed" in sys.argv[1:], vite_commit=vite_commit)
    with open(MARKETPLACE, "w", encoding="utf-8") as f:
        json.dump(marketplace, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("\n".join(changes) if changes else "no upstream changes")


if __name__ == "__main__":
    main()

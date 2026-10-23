# Third-party content

The marketplace lists three plugins that are **not copied** into this repository: they are loaded
straight from their upstream repositories (default branch, no pinning), so upstream changes reach
every session without review here.

| Plugin | Upstream | License |
|---|---|---|
| `agent-sprite-forge` | [0x0funky/agent-sprite-forge](https://github.com/0x0funky/agent-sprite-forge) | MIT |
| `gamedev` (skills list copied into `.claude-plugin/marketplace.json`) | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | Apache-2.0 (NOTICE in the upstream repo) |
| `playwright` (skills list in marketplace.json) | [microsoft/playwright](https://github.com/microsoft/playwright) | Apache-2.0 |

Fetched at runtime by the `agent-plugin` plugin:

- [`@playwright/mcp`](https://github.com/microsoft/playwright-mcp) `0.0.83` (Apache-2.0), started by
  `plugins/agent-plugin/scripts/playwright-mcp.sh` through `npx`.
- PyPI packages `pillow`, `numpy`, `scipy`, `resvg-py` and each repo's own npm dependencies,
  installed by the SessionStart hook in cloud sessions only.

The PixelLab MCP server (`plugins/agent-plugin/.mcp.json`) is a remote service at
`https://api.pixellab.ai/mcp`, used under PixelLab's own terms.

Copied into this repository and synced weekly by `.github/workflows/sync-pxl-skill.yml`
(upstream commit in `plugins/pxl/UPSTREAM_COMMIT`):

| Plugin | Upstream | License |
|---|---|---|
| `pxl` (skill files, `bin/`, `src/`, `types/`, `examples/`; not `docs/` or tests) | [augusto-scarvalho/claude-pxl](https://github.com/augusto-scarvalho/claude-pxl) | MIT (`plugins/pxl/LICENSE`) |

The upstream repo is the skill itself, with `bin/` at its root, which claude.ai rejects in a plugin;
the copy keeps it under `plugins/pxl/skills/pxl-pixel-art/` instead.

`SECURITY-REVIEW.md` records the review of the copies shipped in versions 0.1.0–0.3.2.

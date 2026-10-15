# Third-party content

The marketplace lists two plugins that are **not copied** into this repository: they are loaded
straight from their upstream repositories (default branch, no pinning), so upstream changes reach
every session without review here.

| Plugin | Upstream | License |
|---|---|---|
| `agent-sprite-forge` | [0x0funky/agent-sprite-forge](https://github.com/0x0funky/agent-sprite-forge) | MIT |
| `gamedev` (skills list copied into `.claude-plugin/marketplace.json`) | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | Apache-2.0 (NOTICE in the upstream repo) |

Fetched at runtime by the `agent-plugin` plugin:

- [`@playwright/mcp`](https://github.com/microsoft/playwright-mcp) `0.0.83` (Apache-2.0), started by
  `plugins/agent-plugin/scripts/playwright-mcp.sh` through `npx`.
- PyPI packages `pillow`, `numpy`, `scipy`, `resvg-py` and each repo's own npm dependencies,
  installed by the SessionStart hook in cloud sessions only.

The PixelLab MCP server (`plugins/agent-plugin/.mcp.json`) is a remote service at
`https://api.pixellab.ai/mcp`, used under PixelLab's own terms.

`SECURITY-REVIEW.md` records the review of the copies shipped in versions 0.1.0–0.3.2.

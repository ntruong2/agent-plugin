# Third-party content

The marketplace lists four plugins that are **not copied** into this repository: they are loaded
straight from their upstream repositories. `.github/workflows/sync-upstreams.yml` pins each one daily
(`sha` in marketplace.json) to the newest default-branch commit that touched its skills, so upstream
changes reach every session within a day, without review here.

| Plugin | Upstream | License |
|---|---|---|
| `agent-sprite-forge` | [0x0funky/agent-sprite-forge](https://github.com/0x0funky/agent-sprite-forge) | MIT |
| `gamedev` (skills list copied into `.claude-plugin/marketplace.json`) | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | Apache-2.0 (NOTICE in the upstream repo) |
| `playwright` (skills list in marketplace.json) | [microsoft/playwright](https://github.com/microsoft/playwright) | Apache-2.0 |
| `meowa` (skill `skills/game-assets`) | [Meowa-AI/meowa-skills](https://github.com/Meowa-AI/meowa-skills) | MIT |

Fetched at runtime by the `agent-plugin` plugin:

- [`@playwright/mcp`](https://github.com/microsoft/playwright-mcp) `0.0.83` (Apache-2.0), started by
  `plugins/agent-plugin/scripts/playwright-mcp.sh` through `npx`.
- PyPI packages `pillow`, `numpy`, `scipy`, `resvg-py` and each repo's own npm dependencies,
  installed by the SessionStart hook in cloud sessions only.

The `meowa` skill calls the paid Meowa API at `https://api.meowa.ai`, used under Meowa's own terms.

The PixelLab MCP server (`plugins/agent-plugin/.mcp.json`) is a remote service at
`https://api.pixellab.ai/mcp`, used under PixelLab's own terms.

`SECURITY-REVIEW.md` records the review of the copies shipped in versions 0.1.0–0.3.2.

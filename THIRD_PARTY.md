# Third-party skills

The skills in `plugins/game-dev/skills/` come from these upstream projects (source path and
upstream content hash of each skill: `skills-lock.json`).

| Skills | Upstream | License |
|---|---|---|
| codeart2d, generate2dmap, generate2dmedia, generate2dsprite, video2dsprite | [0x0funky/agent-sprite-forge](https://github.com/0x0funky/agent-sprite-forge) | MIT — `licenses/agent-sprite-forge.LICENSE` |
| audio-design, camera-systems, create-game-assets, dialogue-systems, game-ai, game-feel, game-ui-ux, input-systems, level-design, performance-optimization, phaser-arcade-physics, phaser-core, physics-tuning, procedural-gen, prototype-fast, router, rpg, save-systems, visual-novel | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | Apache-2.0 — `licenses/awesome-gamedev-agent-skills.LICENSE`; NOTICE: `licenses/awesome-gamedev-agent-skills.NOTICE` |

The awesome-gamedev-agent-skills skills are unmodified.

## Local modifications (agent-sprite-forge, MIT)

Made on 2026-10-15 after the review in `SECURITY-REVIEW.md`:

- `generate2dmedia/SKILL.md`, `generate2dmedia/references/route-media.md`,
  `generate2dmedia/references/cli-routes.md`, `generate2dsprite/SKILL.md`, `generate2dmap/SKILL.md`,
  `video2dsprite/SKILL.md`, and one status string in `generate2dmedia/scripts/forge_doctor.py`:
  "a configured key is the owner's consent, no per-call question" replaced by "ask the user
  (route, number of calls, estimated cost) before the first paid call of a session".
- `codeart2d/scripts/fx_build.py`: non-printable characters in the spec name are replaced by `?`
  in the generated runtime's header comment.

## Not included

- `game-assets` from [Meowa-AI/meowa-skills](https://github.com/Meowa-AI/meowa-skills) (MIT), see
  `SECURITY-REVIEW.md`.

## Fetched at runtime (not vendored)

- [`@playwright/mcp`](https://github.com/microsoft/playwright-mcp) `0.0.83` (Apache-2.0), started by
  `plugins/game-dev/bin/playwright-mcp.sh` through `npx`; it pulls `playwright` from npm.
- The SessionStart hook installs `pillow`, `numpy`, `scipy`, `resvg-py` from PyPI and the
  project's own npm dependencies, only in cloud sessions.

## Remote service

The PixelLab MCP server (`plugins/game-dev/.mcp.json`) is a remote service at
`https://api.pixellab.ai/mcp`, used under PixelLab's own terms.

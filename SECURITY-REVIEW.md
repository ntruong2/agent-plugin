# Security review (2026-10-15)

Static review of every script and instruction file in the 25 upstream skills, done before packaging
(14 reviewer agents, every medium/high finding adversarially re-checked). Paths in the report are
from the review checkout. Outcome applied to this plugin:

- `game-assets` (Meowa) is **excluded**: agent-driven self-update outside the plugin, undocumented
  `DEV_API_KEY` fallback, unpinned server-supplied URLs, uncapped paid runs.
- Forge skills patched so a configured API key no longer counts as consent: the agent must tell
  the user the route, calls and estimated cost and wait for a go-ahead before the first paid call
  (see THIRD_PARTY.md, "Local modifications").
- `codeart2d/scripts/fx_build.py`: control characters stripped from the spec name written into the
  generated JS header (verified injection).

---

# Security verdict: agent-plugin plugin skills

**Bottom line:** none of the 14 review jobs found malicious code, hidden network calls or obfuscation. Nothing runs on import or at session start. All 20 confirmed findings were downgraded to low or info on verification. The main risk is that skills spend money without asking: any provider key in the environment is treated as consent to make paid calls, with no default cap. The second risk is game-assets, which is the only skill with an agent-driven self-update that writes outside the plugin.

## 1. Per-skill recommendation

| Skill | Rec. | Why |
|---|---|---|
| audio-design | INCLUDE | Instructional text only; no code, network or credentials. |
| camera-systems | INCLUDE | Instructional text only. |
| dialogue-systems | INCLUDE | Instructional text only. runner.md recommends an AST evaluator instead of eval(). |
| game-ai | INCLUDE | Instructional text only. |
| game-feel | INCLUDE | Instructional text only. Only oddity is a harmless stray U+2592 character at references/feedback-recipes.md:71. |
| game-ui-ux | INCLUDE | Instructional text only. |
| input-systems | INCLUDE | Instructional text only. |
| level-design | INCLUDE | Instructional text only. |
| performance-optimization | INCLUDE | Instructional text only. |
| phaser-arcade-physics | INCLUDE | Instructional text only. |
| phaser-core | INCLUDE | Instructional text only. |
| physics-tuning | INCLUDE | Instructional text only. |
| procedural-gen | INCLUDE | Instructional text only. |
| prototype-fast | INCLUDE | Instructional text only. |
| router | INCLUDE | Broad trigger, but it only reads other skills and announces them (router/SKILL.md:4, :172). |
| rpg | INCLUDE | Instructional text only. |
| save-systems | INCLUDE | Instructional text only. |
| visual-novel | INCLUDE | Instructional text only. |
| create-game-assets | INCLUDE-WITH-NOTE | Scripts are offline. Notes: runtime `pip install -r scripts/requirements.txt` (SKILL.md:97-98), and generation is handed to any installed `imagegen` skill (SKILL.md:60), which was not reviewed. |
| codeart2d | INCLUDE-WITH-NOTE | Explicit-only and offline. Confirmed low: spec-filename JS injection (fx_build.py:648), Chrome `--no-sandbox` as root (codeart_core.py:989). Delete the stray `scripts/__pycache__/` before packaging. |
| generate2dmedia | INCLUDE-WITH-NOTE | Each key goes only to its own vendor's official host, and credential handling is careful. However, a configured key counts as consent: route_media.py always adds `--execute --allow-duplicate`, with no cap by default (SKILL.md:23, :51; route_media.py:461). Set `FORGE_MAX_PAID_REQUESTS` or the `FORGE_SESSION_*` caps, or patch SKILL.md to confirm before the first paid call. |
| generate2dsprite | INCLUDE-WITH-NOTE | Local processing is clean. Paid generation goes through generate2dmedia under the same consent policy (SKILL.md:30), and master_still makes 3 takes per character. |
| generate2dmap | INCLUDE-WITH-NOTE | Clean offline tools. `allow_implicit_invocation: true` (agents/openai.yaml:7) plus a very broad trigger (SKILL.md:3) means level-design requests can start paid image generation. Set it to false. |
| video2dsprite | INCLUDE-WITH-NOTE | Clean local media code. `sprite_set.py run` can generate up to 18 paid clips per character, about $15 worst case, with no prompt (references/sprite-set.md:23). |
| game-assets | EXCLUDE (as shipped) | Combines several problems: an agent-driven self-update that does an unpinned `git pull` and copies into `~/.codex/skills` (meowart_api.md:26, SKILL.md:148); a silent `DEV_API_KEY` credential fallback (meowart_api.py:8344); a server-controlled update URL and `jobs_url` key forwarding; and a broad trigger that sends general game-design questions to an uncapped paid third-party agent. No other skill depends on it. It could be re-included after removing the self-update text, removing the `DEV_API_KEY` fallback, pinning `jobs_url`/`update_url` to Meowa hosts, and requiring confirmation of each paid run. |

## 2. Confirmed findings (real after verification)

All are low or info after verification; none is medium or high.

**game-assets**
- LOW `game-assets/meowart_api.py:2981` — `poll_job_until_done` sends the Bearer key to whatever `jobs_url` the server returns, with no host check. Callers at L4002, L4064, L4144, L4169, L6057.
- LOW `game-assets/meowart_api.py:8344` — falls back to the generic env var `DEV_API_KEY` (from the environment or a `.env` in the working directory) and sends it to api.meowa.ai as `X-Dev-Key`. This is undocumented, so an unrelated secret with that name could leak to Meowa.
- LOW `game-assets/meowart_api.py:561` — on HTTP 426, the server-supplied `update_url` is placed unvalidated into an "Update the Skill from {source}" instruction to the agent.
- LOW `game-assets/meowart_api.md:26` — self-update procedure: `git pull --ff-only` then `cp -R` into `${CODEX_HOME:-$HOME/.codex}/skills/game-assets/`. Also at SKILL.md:148 and references/running-and-outputs.md:33-35. The sha256 in release.json is not enforced anywhere.
- LOW `game-assets/SKILL.md:148` — the same update guidance, triggered after a runner failure.
- LOW `game-assets/references/capability-routing.md:103` (the row is actually at line 7) — game-design requests are routed to `game-design-run`, which bills per token with no per-run maximum (game-design.md:80).
- LOW `game-assets/SKILL.md:152` — the `*-run` chains upload prompts, images, video, Spine ZIPs and voice audio, with no confirmation of each charge.

**generate2dmedia**
- LOW `generate2dmedia/SKILL.md:23` — "A configured key is the owner's consent"; no cap by default (SKILL.md:51).
- LOW `generate2dmedia/scripts/route_media.py:461` — always adds `--allow-duplicate`, and adds `--execute` unless `--dry-run`. `SESSION_DEFAULTS` are None (media_ledger.py:44).
- LOW `generate2dmedia/scripts/route_media.py:701` — the `FORGE_ROUTE_MEDIA_FAKE` test hook (read at L760-762) runs any named executable with the full environment.
- LOW `generate2dmedia/scripts/media_providers.py:388` — the host each key goes to comes from the data file `references/capabilities.json` (`apiBase`), which is never validated in code.
- LOW `generate2dmedia/scripts/generate_media.py:994` — fal.ai reference images are uploaded to the public fal CDN at v3.fal.media. Opt-out: `fal_upload=data`.

**generate2dsprite**
- LOW `generate2dsprite/SKILL.md:30` — the same key-equals-consent policy.
- INFO `generate2dsprite/scripts/master_still.py:810` — `--media-cli` or `FORGE_ROUTE_MEDIA_FAKE` replaces the media CLI. This is a documented developer seam and crosses no trust boundary.

**video2dsprite**
- LOW `video2dsprite/scripts/sprite_set.py:1914` — sends input.png (also as `--last-frame`) and the prompt to paid video APIs through route_media.py.
- LOW `video2dsprite/references/sprite-set.md:23` — `--max-takes 3` × 6 actions = up to 18 clips, roughly $15 per character at xAI's $0.14/s.

**codeart2d**
- LOW `codeart2d/scripts/fx_build.py:648` — a spec filename containing a newline injects JavaScript into fx-runtime.mjs, which node then runs during verification. The verifier reproduced this. Fix: strip control characters from the name.
- LOW `codeart2d/scripts/fx_verify.mjs:452` — imports the module under test with full Node privileges. The forbidden-API scan (L38) is advisory only and misses static `import`.
- LOW `codeart2d/scripts/codeart_core.py:989` — the Chrome fallback adds `--no-sandbox` when euid is 0. The SVG lint does not check `url()` values.

**generate2dmap**
- INFO `generate2dmap/scripts/build_scene_preview.py:1644` — `--verify` runs `node -` with the full environment and loads whatever `playwright` package resolves from the project.

**Rejected:** `master_still.py:871` (child process inherits the full environment) was judged not real (info).

**Unverified reviewer lows worth patching** (only medium and high findings were adversarially verified):
- meowart_api.py:2672 sets `confirmPaidTools: False` with a 200-credit budget cap.
- meowart_api.py:3369 and :3636: `--api-job-id` is used unsanitized, so `../` can escape the output directory.
- meowart_api.py:4198: uploads have no file-type check.
- master_still.py:976 and sprite_set.py:1954: a file the child process reports as its output is copied into the project, even from outside the output folder.
- sprite_set.py:1540: the `FORGE_FINISH_FRAMES` exec hook.
- forge_av.py:450: ffmpeg runs without `-protocol_whitelist`.
- generate_media.py:1167: batch jobs-file paths are not confined.
- media_ledger.py:324: `.forge/` holds prompt copies in the user's repo.
- cli_media.py:1749: reads Codex session rollout transcripts.
- generate2dsprite.py:1889: `--overwrite` can replace any caller-named file.

## 3. External hosts contacted

| Host | Skill / file | When | What is sent | Credential (env var) |
|---|---|---|---|---|
| api.meowa.ai | game-assets/meowart_api.py | Any runner subcommand, never on import. Catalog search commands are unauthenticated. | Prompts, game-design text, images, MP4/GIF/WebP, Spine ZIPs (up to 50 MB), voice reference audio, params, and version/User-Agent headers | `MEOWART_API_KEY` (Bearer), else `DEV_API_KEY` (X-Dev-Key). Read from the environment or `.env` in the working directory, skill dir or skill parent dir. |
| Any host in a server-returned `jobs_url` | game-assets/meowart_api.py:2981 | Polling remove-background, pixelate, self-loop, music and workflow jobs | GET request | The same Meowa key (unpinned host) |
| media-cn.meowjito.com, media.meowjito.com, other server-chosen HTTPS media hosts | game-assets/meowart_api.py:1712 | Final downloads, map/texture reference downloads | Unauthenticated GET | None (auth only if the host is api.meowa.ai) |
| github.com/Meowa-AI/meowa-skills | game-assets (meowart_api.md:26) | Agent-driven update after a runner failure | git fetch; pulls executable code | None |
| meowa.ai | game-assets docs | Browser links for the user only | Nothing automatic | — |
| 127.0.0.1:<port> (inbound) | game-assets/scripts/map-preview-server.py:566 | Explicit run; stops after `--lifetime` (900 s default) | Serves selected PNG/WebP files and a config | — |
| api.openai.com | generate2dmedia (via route_media.py; used by generate2dsprite, generate2dmap, video2dsprite) | Image requests when the key is set; executes immediately | Prompt, up to 16 reference images | `OPENAI_API_KEY` |
| generativelanguage.googleapis.com | generate2dmedia | Image requests | Prompt, inline reference images | `GOOGLE_API_KEY` / `GEMINI_API_KEY` (x-goog-api-key) |
| api.x.ai | generate2dmedia, video2dsprite sprite_set | Images and image-to-video clips, plus polling and resume | Prompt, master still, last frame, keyframes, references | `XAI_API_KEY` |
| ark.ap-southeast.bytepluses.com | generate2dmedia | Seedream images, Seedance video | Prompt, reference and frame images as data URIs | `ARK_API_KEY` |
| queue.fal.run | generate2dmedia | fal jobs and status polling (host-checked) | Prompt, image URLs, parameters | `FAL_KEY` |
| rest.fal.ai | generate2dmedia | Before each fal job that has images | Token request | `FAL_KEY` |
| v3.fal.media | generate2dmedia | Right after the token request | Raw reference images to the public CDN, kept 7 days or more | Short-lived fal token, not `FAL_KEY` |
| Provider result URLs (any HTTPS host, up to 3 redirects) | generate2dmedia/scripts/generate_media.py:575 | After a job completes or on resume | GET with User-Agent only | Gemini key only if the URL is on the Gemini host |
| User `--base-url` host | generate2dmedia | Only with `--allow-custom-base-url` | Full request | That provider's key |
| OpenAI / xAI backends via the `codex` / `grok` CLIs | generate2dmedia/scripts/cli_media.py | Fallback when no key is set; no per-call question | Prompt and reference images | The user's CLI sign-in; API keys are removed from the child's environment |
| PyPI, npm registry, Playwright browser CDN | create-game-assets, game-assets, codeart2d, generate2dmap docs | Only if the optional install hints are followed | Package requests | None |
| **api.pixellab.ai/mcp** | **plugin root `.mcp.json` (not in any skill review)** | **MCP connection in every session that loads the plugin** | MCP traffic | **`PIXELLAB_API_KEY` (Bearer)** |

Two indirect cases: headless Chrome can fetch a `url()` inside an SVG (codeart2d), and ffmpeg can open URLs from a crafted playlist file (forge_av).

## 4. Coverage gaps

- **Jobs:** all 14 review jobs returned results; none were dropped.
- **Code coverage:** every .py, .mjs, .js and .html file under `skills/` was read in full by at least one job, either directly or through a byte-identical vendored copy. I checked this by hash. Several reviewers called these helpers "unreviewed" because they did not know the copies were identical:

  | Helper | Copies | Read in full by |
  |---|---|---|
  | forge_core.py | 4, identical (sha f227ac7f…) | codeart2d#2 |
  | forge_nav.py | 2 | codeart2d#2 |
  | forge_schema.py | 3 | codeart2d#2 |
  | forge_matte.py | 3 | generate2dmap#2 |
  | forge_av.py | 2 | generate2dmap#2 |
  | forge_palette.py | 2 | generate2dsprite#1 (inferred: its 9,448-line total matches this file set exactly) |

- **Partially covered:**
  - `codeart2d/references/runtime/fx-template.mjs` (322 lines) is not named by any job. My grep found no imports, network calls, eval or `process` use; the only `import` match is a comment at line 7.
  - The 12 `references/schemas/*.schema.json` files were grepped only.
  - `game-assets/web_parameter_contract.json` was parsed and its values checked, not read line by line.
- **Not reviewed at all:**
  - Plugin root `.mcp.json` (PixelLab remote MCP, which sends `PIXELLAB_API_KEY` to api.pixellab.ai) and `.claude-plugin/plugin.json`.
  - `skills-lock.json` and `licenses/`.
  - External binaries the skills run: codex, grok, ffmpeg/ffprobe, Chrome/Edge, node/playwright, resvg-js-cli.
  - Any workspace `imagegen` skill.
- **Artifacts to remove before packaging:** `codeart2d/scripts/__pycache__/` holds three cpython-313 .pyc files, timestamp-based, created at 04:26, after the 04:06 install. They were most likely generated while the reviewers or verifier ran code locally. No other files newer than the install were found under /home/user/claude-game-plugin.
- **Method limits:**
  - Low and info findings were not adversarially verified.
  - Review was static, apart from the verifier's fx_build.py proof of concept.
  - The two documentation jobs (md-forge, md-other) reported behaviour from the docs; the matching code was checked separately by the script jobs.

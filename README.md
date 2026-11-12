# Agent Plugin

Marketplace Claude Code `agent-plugin` gồm 6 plugin:

| Plugin | Nội dung | Nguồn |
|---|---|---|
| **Agent Plugin** (`agent-plugin`) | Hook tự cài công cụ, MCP `pixellab` và `playwright`, nhắc "hỏi trước khi gọi API trả phí" | repo này |
| **Agent Sprite Forge** (`agent-sprite-forge`) | 5 skill vẽ: `generate2dsprite`, `generate2dmap`, `generate2dmedia`, `video2dsprite`, `codeart2d` | [0x0funky/agent-sprite-forge](https://github.com/0x0funky/agent-sprite-forge), nhánh mặc định |
| **gamedev** | 75 skill làm game (router, Phaser, Godot, Unity, Unreal, UI/UX, game feel, level design, RPG, …) | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills), nhánh mặc định |
| **Playwright** (`playwright`) | 3 skill của Playwright: `playwright-cli`, `playwright-component-testing`, `playwright-trace` | [microsoft/playwright](https://github.com/microsoft/playwright), nhánh mặc định |
| **Vite** (`vite`) | Skill `vite`, `vitest`, `pnpm` | chép từ [antfu/skills](https://github.com/antfu/skills) vào `plugins/vite`, GitHub Action đồng bộ hằng ngày |
| **Meowa** (`meowa`) | Skill `game-assets`: tài liệu thiết kế game, sprite pixel/HD, UI, tileset, map, animation, video, âm thanh, nhạc, lồng tiếng qua API Meowa (trả phí theo credit) | [Meowa-AI/meowa-skills](https://github.com/Meowa-AI/meowa-skills), nhánh mặc định |

- Các plugin skill **tự cập nhật theo repo gốc** (không rà trước): GitHub Action
  `sync-upstreams.yml` chạy hằng ngày, ghim mỗi plugin nạp từ GitHub vào commit mới nhất có đổi phần
  skill (`sha` trong `.claude-plugin/marketplace.json`) và đổi `version` của Vite khi bản chép thay
  đổi. claude.ai đồng bộ lại marketplace khi `marketplace.json` đổi, nên bản mới tới trong vòng một
  ngày. Danh sách skill của `gamedev` được chép trong `marketplace.json`: skill mới ở upstream chỉ
  hiện sau khi cập nhật danh sách này.
- Skill `game-assets` (Meowa) gọi `https://api.meowa.ai`, key từ biến môi trường `MEOWART_API_KEY`; cần Python `requests` và `Pillow`.
- MCP `pixellab`: `https://api.pixellab.ai/mcp`, token từ biến môi trường `PIXELLAB_API_KEY`.
- MCP `playwright`: `@playwright/mcp@0.0.83` qua `npx`, trình duyệt headless.
- MCP `godot`: `@coding-solo/godot-mcp@0.1.1` qua `npx` (chạy editor, chạy project, đọc log gỡ lỗi, tạo scene, thêm node). Cần file chạy Godot trên máy: đặt `GODOT_PATH=/đường/dẫn/godot`, hoặc để `godot` trong PATH; hook chưa tự cài Godot.
- Nguồn và giấy phép: [THIRD_PARTY.md](THIRD_PARTY.md).

## Tự cài công cụ (hook SessionStart)

Khi phiên bắt đầu hoặc được mở lại, hook kiểm tra (dưới 1 giây khi đã đủ):

- thư viện Python của skill vẽ: `pillow numpy scipy resvg-py`;
- Chromium cho Playwright (`/opt/pw-browsers/chromium`, `PLAYWRIGHT_BROWSERS_PATH` hoặc thư mục cache của Playwright);
- repo trong `/home/user/*` có `package.json` mà chưa có `node_modules`.

Trong **phiên cloud** (`CLAUDE_CODE_REMOTE=true`) hook cài phần thiếu **ở chế độ nền** rồi trả về ngay:

- Repo được cài đúng theo file lock (`pnpm install --frozen-lockfile`, `yarn install --frozen-lockfile`,
  `npm ci`); không có file lock thì `npm install --no-package-lock`. Hook **không bao giờ sửa file lock**
  và không đổi pnpm/yarn toàn cục (dùng `corepack pnpm …`).
- Cài lỗi thì ghi nhận và **không thử lại** cho tới khi `package.json`/file lock đổi.
- Nhật ký: `~/.cache/agent-plugin/setup.log`; xong thì có `~/.cache/agent-plugin/setup.done` (tóm tắt).
  Claude được nhắc chờ file này trước khi chạy test; sau `/clear` hay nén ngữ cảnh mà vẫn đang cài
  thì hook nhắc lại.
- Chỉ một trình cài chạy tại một thời điểm (khoá `setup.lock.d`).

Trên **máy cá nhân** hook không cài gì, chỉ nhắc phần còn thiếu. Biến điều chỉnh:
`AGENT_PLUGIN_AUTOINSTALL=1` (cho cài ở máy cá nhân; Python cài bằng `pip --user`),
`AGENT_PLUGIN_REPO_INSTALL=0` (không cài dependency repo), `AGENT_PLUGIN_CHROMIUM=<đường dẫn>`.

MCP `playwright` lưu ảnh chụp và snapshot ở `~/.cache/agent-plugin/playwright-mcp`, không ghi vào repo.

Setup script của môi trường cloud vì vậy có thể để trống (`exit 0`).

## Cài cho mọi phiên

1. claude.ai → **Customize → Plugins → Add → Add marketplace** → `https://github.com/ntruong2/agent-plugin`
   (repo private: cần đã kết nối GitHub và Claude GitHub App có quyền vào repo này).
2. Bật **Agent Plugin**, **Agent Sprite Forge**, **gamedev**, **Playwright**, **Vite**, **Meowa**; bật **Sync automatically** nếu có.
3. Thêm biến môi trường `PIXELLAB_API_KEY` (và `MEOWART_API_KEY` nếu dùng Meowa) vào môi trường cloud (menu môi trường → Edit).

Trên máy cá nhân (CLI):

```bash
claude plugin marketplace add ntruong2/agent-plugin
claude plugin install agent-plugin@agent-plugin
claude plugin install agent-sprite-forge@agent-plugin
claude plugin install gamedev@agent-plugin
claude plugin install playwright@agent-plugin
claude plugin install vite@agent-plugin
claude plugin install meowa@agent-plugin
```

Ghi chú: trên claude.ai bản web (chat/Cowork) hook và MCP `playwright` bị bỏ qua; chúng chạy trong
Claude Code (phiên cloud và CLI).

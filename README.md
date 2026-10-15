# agent-plugin

Marketplace Claude Code chứa plugin **`agent-plugin`**: 24 skill làm game, MCP **PixelLab** và **Playwright**,
cùng hook tự cài công cụ trong phiên cloud, để mọi phiên Claude Code (mọi repo) có cùng bộ công cụ.

| Thành phần | Nội dung |
|---|---|
| Vẽ (Agent Sprite Forge) | `generate2dsprite`, `generate2dmap`, `generate2dmedia`, `video2dsprite`, `codeart2d` |
| Làm game | `router`, `phaser-core`, `phaser-arcade-physics`, `game-ui-ux`, `game-feel`, `level-design`, `camera-systems`, `input-systems`, `audio-design`, `save-systems`, `procedural-gen`, `game-ai`, `dialogue-systems`, `rpg`, `visual-novel`, `physics-tuning`, `performance-optimization`, `prototype-fast`, `create-game-assets` |
| MCP | `pixellab` — `https://api.pixellab.ai/mcp`, token đọc từ biến môi trường `PIXELLAB_API_KEY` |
| MCP | `playwright` — `@playwright/mcp@0.0.83` qua `npx` (trình duyệt headless: mở trang, chụp màn hình, bấm, đọc console). Dùng Chromium có sẵn ở `/opt/pw-browsers/chromium` nếu có |
| Hook SessionStart | `hooks/ensure-deps.sh` — xem mục "Tự cài công cụ" |

- Nguồn, giấy phép và các chỗ đã sửa: [THIRD_PARTY.md](THIRD_PARTY.md).
- Kết quả rà bảo mật: [SECURITY-REVIEW.md](SECURITY-REVIEW.md). Skill `game-assets` (Meowa) bị loại.
- Skill vẽ chỉ gọi API trả phí sau khi hỏi bạn (đường đi, số lượt, chi phí ước tính).
- Skill Phaser viết cho Phaser 4; dự án Phaser 3 cần đối chiếu API.

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

1. claude.ai → **Customize → Plugins → Add → Add marketplace** → nhập `ntruong2/agent-plugin`
   (repo private: cần đã kết nối GitHub và cấp cho Claude GitHub App quyền vào repo này).
2. Bật plugin **agent-plugin**. Phiên mới sẽ có các skill.
3. PixelLab: thêm **biến môi trường** `PIXELLAB_API_KEY` vào môi trường cloud (menu môi trường →
   Edit). Biến gắn theo môi trường, mỗi môi trường thêm một lần. Dùng biến môi trường thường;
   token để trong "Network secrets" có thể không tới được MCP.
4. Mở phiên mới để kiểm tra: skill có trong danh sách, công cụ `pixellab` trả lời.

Trên máy cá nhân (CLI):

```bash
claude plugin marketplace add ntruong2/agent-plugin
claude plugin install agent-plugin@agent-plugin
```

## Cập nhật skill từ upstream

Chép lại thư mục skill từ repo nguồn (đường dẫn trong `skills-lock.json`), áp lại các chỗ sửa
trong THIRD_PARTY.md, rà lại phần thay đổi, tăng `version` trong
`plugins/agent-plugin/.claude-plugin/plugin.json` và `.claude-plugin/marketplace.json`, rồi:

```bash
claude plugin validate .
claude plugin validate plugins/agent-plugin
```

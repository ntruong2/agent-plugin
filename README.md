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

Mỗi khi phiên bắt đầu, hook kiểm tra (mất dưới 1 giây khi đã đủ):

- thư viện Python của skill vẽ: `pillow numpy scipy resvg-py`;
- Chromium cho Playwright (`/opt/pw-browsers/chromium` hoặc `~/.cache/ms-playwright`);
- repo trong `/home/user/*` có `package.json` mà chưa có `node_modules` (cài bằng pnpm/yarn/npm theo file lock).

Trong **phiên cloud** (`CLAUDE_CODE_REMOTE=true`) hook cài phần thiếu **ở chế độ nền** rồi trả về ngay;
nhật ký ở `~/.cache/agent-plugin/setup.log`, xong thì có `~/.cache/agent-plugin/setup.done`
(Claude được nhắc chờ file này trước khi chạy test). Trên **máy cá nhân** hook không cài gì,
chỉ nhắc phần còn thiếu. Biến điều chỉnh: `AGENT_PLUGIN_AUTOINSTALL=1` (cho phép cài ở máy cá nhân),
`AGENT_PLUGIN_REPO_INSTALL=0` (không cài dependency repo), `AGENT_PLUGIN_CHROMIUM=<đường dẫn>`.

Setup script của môi trường cloud vì vậy có thể để trống. Nếu vẫn giữ, nó chạy trước và được lưu
bộ nhớ đệm, hook sẽ thấy đã đủ và không làm gì.

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

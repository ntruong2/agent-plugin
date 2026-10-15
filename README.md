# claude-game-plugin

Marketplace Claude Code chứa plugin **`game-dev`**: 24 skill làm game và MCP **PixelLab**,
để mọi phiên Claude Code (mọi repo) có cùng bộ công cụ.

| Thành phần | Nội dung |
|---|---|
| Vẽ (Agent Sprite Forge) | `generate2dsprite`, `generate2dmap`, `generate2dmedia`, `video2dsprite`, `codeart2d` |
| Làm game | `router`, `phaser-core`, `phaser-arcade-physics`, `game-ui-ux`, `game-feel`, `level-design`, `camera-systems`, `input-systems`, `audio-design`, `save-systems`, `procedural-gen`, `game-ai`, `dialogue-systems`, `rpg`, `visual-novel`, `physics-tuning`, `performance-optimization`, `prototype-fast`, `create-game-assets` |
| MCP | `pixellab` — `https://api.pixellab.ai/mcp`, token đọc từ biến môi trường `PIXELLAB_API_KEY` |

- Nguồn, giấy phép và các chỗ đã sửa: [THIRD_PARTY.md](THIRD_PARTY.md).
- Kết quả rà bảo mật: [SECURITY-REVIEW.md](SECURITY-REVIEW.md). Skill `game-assets` (Meowa) bị loại.
- Skill vẽ chỉ gọi API trả phí sau khi hỏi bạn (đường đi, số lượt, chi phí ước tính).
- Skill Phaser viết cho Phaser 4; dự án Phaser 3 cần đối chiếu API.

## Cài cho mọi phiên

1. claude.ai → **Customize → Plugins → Add → Add marketplace** → nhập `ntruong2/claude-game-plugin`
   (repo private: cần đã kết nối GitHub và cấp cho Claude GitHub App quyền vào repo này).
2. Bật plugin **game-dev**. Phiên mới sẽ có các skill.
3. PixelLab: thêm **biến môi trường** `PIXELLAB_API_KEY` vào môi trường cloud (menu môi trường →
   Edit). Biến gắn theo môi trường, mỗi môi trường thêm một lần. Dùng biến môi trường thường;
   token để trong "Network secrets" có thể không tới được MCP.
4. Mở phiên mới để kiểm tra: skill có trong danh sách, công cụ `pixellab` trả lời.

Trên máy cá nhân (CLI):

```bash
claude plugin marketplace add ntruong2/claude-game-plugin
claude plugin install game-dev@claude-game-plugin
```

## Cập nhật skill từ upstream

Chép lại thư mục skill từ repo nguồn (đường dẫn trong `skills-lock.json`), áp lại các chỗ sửa
trong THIRD_PARTY.md, rà lại phần thay đổi, tăng `version` trong
`plugins/game-dev/.claude-plugin/plugin.json` và `.claude-plugin/marketplace.json`, rồi:

```bash
claude plugin validate .
claude plugin validate plugins/game-dev
```

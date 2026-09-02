# AGENTS.md — Quy tắc cho AI Agent trong dự án này

## Bối cảnh dự án
- Engine: Godot 4.7 (4.7.2-stable), ngôn ngữ chính: GDScript
- Thể loại: Thủ thành / Base Defense hậu tận thế (2.5D màn hình dọc)
- Nền tảng: Android (CH Play), có thể mở rộng iOS sau

## Việc được phép làm
- Sửa/thêm code trong `scripts/`, `scenes/` theo đúng phạm vi task được giao
- Viết test trong `tests/` cho mọi system mới
- Cập nhật `docs/changelog.md` sau mỗi thay đổi đáng kể
- (Chỉ Antigravity, Phase 0) Tạo cấu trúc thư mục, file rỗng có comment TODO, Resource schema (chỉ field, không logic), file `.tres` data mẫu, đăng ký autoload (tên + đường dẫn) trong `project.godot`

## Việc KHÔNG được làm
- Không tự ý sửa file trong `assets/art/exported/` (đây là output từ Blender)
- Không refactor toàn bộ codebase nếu không được yêu cầu rõ ràng
- Không thêm dependency/plugin mới mà không hỏi trước
- Không sửa `project.godot` export settings (keystore, package name...) trừ khi được giao rõ
- (Antigravity) Không viết logic gameplay (thân hàm, điều kiện if/else mang tính game rule) trong `scripts/systems/` hoặc `scripts/entities/` — chỉ Codex được làm việc này
- (Antigravity) Không tự đặt số liệu balance chính thức — chỉ data mẫu để test khung chạy được

## Quy ước code
- Đặt tên biến/hàm: snake_case (chuẩn GDScript)
- Mỗi system tách riêng 1 file, tránh file > 300 dòng
- Dùng signal (EventBus autoload) thay vì gọi chéo trực tiếp giữa các node khi có thể
- Comment ngắn gọn giải thích "tại sao", không giải thích "cái gì" (code đã tự nói)

## Quy trình khi nhận task
1. Đọc kỹ yêu cầu, nếu mơ hồ thì hỏi lại trước khi code
2. Với task lớn (>1 file, >1 system liên quan): viết plan ngắn trước, chờ duyệt
3. Với task nhỏ (bugfix, 1 hàm): code thẳng, giải thích thay đổi trong PR/commit message
4. Luôn chạy test liên quan trước khi báo hoàn thành
5. **Bắt buộc tự kiểm tra theo "Definition of Done" bên dưới trước khi báo "đã xong" — không được bỏ qua bước này**

## Definition of Done — bắt buộc cho MỌI task, không có ngoại lệ

Task chỉ được coi là hoàn thành khi agent **tự thực hiện và dán ra** đủ 4 mục sau trong câu trả lời cuối cùng. Không được viết "đã hoàn thành" nếu thiếu bất kỳ mục nào bên dưới:

1. **Danh sách file đã tạo/sửa** — liệt kê đầy đủ đường dẫn tuyệt đối, không được nói chung chung kiểu "đã tạo các file cần thiết"
2. **Đối chiếu từng gạch đầu dòng của yêu cầu gốc** — copy lại từng yêu cầu đã được giao, đánh dấu ✅ (đã làm, có bằng chứng) hoặc ❌ (chưa làm/không chắc) — nếu có bất kỳ ❌ nào, PHẢI tự sửa trước khi báo xong, không được báo xong rồi để đó
3. **Xác nhận đã đọc lại nội dung file vừa tạo** — không chỉ chạy lệnh tạo file rồi tin là đúng, phải `view`/`cat` lại ít nhất những file quan trọng để confirm nội dung khớp yêu cầu (đúng field, đúng comment TODO, không lẫn logic vào file scaffold...)
4. **Nêu rõ điều gì CHƯA làm hoặc cần người review quyết định** — nếu có phần nào mơ hồ mà agent tự chọn 1 phương án, phải nói rõ đã tự quyết gì, để người dùng biết mà kiểm tra lại

**Agent không được tự merge hoặc coi task là "đóng" nếu chưa đưa ra đủ 4 mục trên.** Nếu người dùng phát hiện thiếu sót sau khi agent đã báo "xong", agent phải coi đây là lỗi nghiêm trọng của chính nó, không đổ lỗi cho việc yêu cầu chưa rõ (trừ khi thực sự chưa rõ và agent đã hỏi lại từ đầu mà không được trả lời).


## Git
- Nhánh: `feature/<ten-tinh-nang>`, `fix/<ten-bug>`
- Commit message: `[loại] mô tả ngắn` — ví dụ: `[feat] thêm hệ thống inventory`, `[fix] sửa lỗi save game bị mất item`
- Không commit trực tiếp vào `main`

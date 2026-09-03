# Setup quy trình làm Game với AI Agent (Godot + Codex + Antigravity + Blender)

## 0. Nguyên tắc chung
- Codex là **agent chính**: chịu trách nhiệm code gameplay, systems, bugfix.
- Antigravity là **agent phụ**: lên plan/scaffold tính năng mới, viết test, sinh tài liệu, chạy task nền (asset batch, refactor lớn có giám sát).
- Không để 2 agent sửa cùng một file trong cùng một thời điểm — luôn làm việc theo nhánh Git riêng, merge thủ công.
- Mọi agent đều phải đọc file `AGENTS.md` ở gốc repo trước khi bắt đầu (Codex tự đọc, Antigravity cần bạn trỏ vào file này trong Plan mode).

---

## 1. Cấu trúc thư mục dự án Godot

```
game-project/
├── AGENTS.md                # Luật cho AI agent (xem mục 2)
├── README.md                 # Tổng quan dự án, cách build/run
├── project.godot
├── addons/                   # Plugin Godot (nếu có)
├── assets/
│   ├── art/
│   │   ├── raw/               # File Blender gốc (.blend)
│   │   └── exported/          # .glb/.gltf/.png đã export, KHÔNG sửa tay
│   ├── audio/
│   └── fonts/
├── scenes/
│   ├── core/                  # Scene hệ thống: main menu, game manager
│   ├── levels/
│   └── ui/
├── scripts/
│   ├── systems/                # Inventory, save/load, spawn, economy...
│   ├── entities/                # Player, enemy, item logic
│   ├── resources/                # Định nghĩa Resource (EnemyData, WeaponData, HeroData) — data schema, KHÔNG chứa logic
│   └── autoload/                 # Singleton (GameState, EventBus...)
├── data/
│   ├── enemies/                 # File .tres theo schema EnemyData
│   ├── weapons/                 # File .tres theo schema WeaponData
│   └── heroes/                  # File .tres theo schema HeroData
├── tests/                      # Unit test (GUT hoặc tương tự)
├── docs/
│   ├── design-doc.md            # Game design document
│   ├── changelog.md
│   └── decisions/                # Ghi lại quyết định kỹ thuật quan trọng (ADR ngắn)
└── .github/
    └── workflows/
        └── build-android.yml    # CI build APK/AAB tự động
```

**Quy tắc:** thư mục `assets/art/exported/` là file build ra từ Blender, agent (và cả bạn) không sửa tay trực tiếp trong Godot — luôn sửa ở `.blend` rồi export lại, để tránh lệch pipeline.

### 1.1 Thứ tự triển khai thực tế

**Antigravity dựng khung trước → Codex code logic sau.** Lý do: Antigravity tạo folder, file rỗng, resource schema (chỉ khai báo field, không có hàm xử lý) — việc này không rủi ro và không tốn token của Codex để "đoán" cấu trúc dự án. Codex mở ra là thấy sẵn khung + comment `# TODO(Codex): ...` chỉ đúng việc cần làm.

1. **Antigravity — Phase 0 (làm trước tiên):** tạo toàn bộ cây thư mục ở trên, các file rỗng có comment mô tả, các file Resource schema (mục 1.2), file `.tres` mẫu với vài dòng data giả để test, đăng ký autoload trong `project.godot` (chỉ đăng ký tên + đường dẫn script, KHÔNG đụng vào export/signing settings).
2. **Bạn duyệt lại khung** — kiểm tra tên file/thư mục đúng ý trước khi giao Codex, tránh Codex code nhầm chỗ phải sửa lại tốn token.
3. **Codex — Sprint 1** — theo task list ở mục 7.1, điền logic vào đúng các file đã có sẵn.

### 1.2 Nội dung scaffold cụ thể — giao cho Antigravity

**File Resource schema** (chỉ khai báo field, đây là "khuôn dữ liệu" không phải logic gameplay, nên an toàn để Antigravity tạo):

`scripts/resources/enemy_data.gd`
```gdscript
class_name EnemyData
extends Resource

@export var id: String
@export var display_name: String
@export var max_hp: float = 10.0
@export var move_speed: float = 100.0
@export var damage_to_base: float = 1.0
@export var exp_value: int = 1
@export var model_scene: PackedScene
```

`scripts/resources/weapon_data.gd`
```gdscript
class_name WeaponData
extends Resource

enum TargetType { SINGLE, MULTI }
enum RangeType { CLOSE, MID }

@export var id: String
@export var display_name: String
@export var target_type: TargetType = TargetType.SINGLE
@export var range_type: RangeType = RangeType.MID
@export var base_damage: float = 5.0
@export var fire_rate: float = 1.0
@export var upgrade_cost_curve: Array[int] = []
```

`scripts/resources/hero_data.gd`
```gdscript
class_name HeroData
extends Resource

@export var id: String
@export var display_name: String
@export var max_level_per_run: int = 15
@export var stat_growth_per_level: float = 1.1
@export var model_scene: PackedScene
```

**File `.tres` mẫu** (Antigravity tạo 2-3 entry giả để có data test, Codex sẽ tinh chỉnh số liệu thật sau khi có playtest):

`data/enemies/enemy_grunt.tres` — 1 quái thường mẫu, `data/enemies/enemy_boss_stage1.tres` — 1 boss mẫu. Tương tự cho `data/weapons/` (2 vũ khí mẫu: 1 đơn mục tiêu tầm trung, 1 đa mục tiêu tầm gần) và `data/heroes/` (2-3 hero mẫu).

**Các file rỗng cần tạo với comment TODO** (Antigravity tạo file + dòng đầu là comment, không viết thân hàm):

```
scripts/autoload/game_state.gd       # TODO(Codex): xem mục 7.1 task 1
scripts/autoload/event_bus.gd         # TODO(Codex): xem mục 7.1 task 1
scripts/systems/energy_system.gd       # TODO(Codex): xem mục 7.1 task 2
scripts/systems/base_health_system.gd   # TODO(Codex): xem mục 7.1 task 3
scripts/systems/wave_manager.gd          # TODO(Codex): xem mục 7.1 task 4
scripts/systems/level_system.gd           # TODO(Codex): xem mục 7.1 task 5
scripts/systems/hero_system.gd             # TODO(Codex): xem mục 7.1 task 6
scripts/systems/weapon_system.gd            # TODO(Codex): xem mục 7.1 task 7
scripts/systems/save_system.gd               # TODO(Codex): xem mục 7.1 task 9
```

Mỗi comment TODO nên ghi rõ số mục trong `AGENTS.md`/design doc này để Codex tra cứu nhanh, không cần đọc lại toàn bộ tài liệu.

**Việc Antigravity KHÔNG được làm ở Phase 0:** viết thân hàm xử lý logic bên trong các file trên, viết điều kiện `if/else` mang tính gameplay, hoặc tự đặt số liệu balance chính thức (chỉ số liệu mẫu để test khung chạy được).

---


## 2. File `AGENTS.md` mẫu (đặt ở gốc repo)

```markdown
# AGENTS.md — Quy tắc cho AI Agent trong dự án này

## Bối cảnh dự án
- Engine: Godot 4.x, ngôn ngữ chính: GDScript
- Thể loại: [điền thể loại game của bạn]
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

## Quy tắc riêng cho Antigravity (đúc kết từ sự cố thực tế trong dự án)

- **Antigravity PHẢI dừng lại sau khi trình bày plan**, chờ người dùng gõ rõ ràng "duyệt" / "tiến hành" mới được thực thi. Nếu IDE của Antigravity có cơ chế tự động chạy tiếp sau khi tạo plan (từng xảy ra thực tế, log hiện "Auto-proceeded with Implementation Plan"), Antigravity phải **chủ động báo cho người dùng biết việc này đang xảy ra** và đề nghị tắt đi — không được lợi dụng cơ chế đó để bỏ qua bước chờ duyệt. Việc "task lớn phải chờ duyệt" ở mục "Quy trình khi nhận task" áp dụng cho Antigravity nghiêm ngặt hơn Codex, vì Antigravity hay đụng vào nhiều file scene/script cùng lúc.
- **Antigravity KHÔNG được tự chạy lệnh `git`** (`checkout`, `add`, `commit`, `push`) trong môi trường này — đã xác nhận thực tế: sandbox Windows chặn quyền truy cập ổ hệ thống khi Antigravity gọi `run_command` cho git/shell. Antigravity chỉ cần liệt kê đầy đủ, chính xác file đã tạo/sửa trong báo cáo Definition of Done; người dùng sẽ tự chạy git. Antigravity không được hứa "sẽ tự commit" hay báo commit đã xong nếu chưa thực sự chạy được lệnh — nếu lệnh thất bại, phải báo thất bại rõ ràng ngay, không im lặng bỏ qua.

## Git
- Nhánh: `feature/<ten-tinh-nang>`, `fix/<ten-bug>`
- Commit message: `[loại] mô tả ngắn` — ví dụ: `[feat] thêm hệ thống inventory`, `[fix] sửa lỗi save game bị mất item`
- Không commit trực tiếp vào `main`
```

Bạn nên sửa lại phần "Bối cảnh dự án" và "Thể loại" theo game cụ thể bạn chọn.

---

## 3. Phân công Codex vs Antigravity theo loại task

| Loại task | Agent phù hợp | Vì sao |
|---|---|---|
| Viết gameplay logic mới (1 system rõ ràng) | Codex | Giỏi triển khai chi tiết khi có spec rõ |
| Thiết kế kiến trúc/scaffold tính năng lớn | Antigravity (Plan mode) | Antigravity tạo Plan Artifact trước khi code, tốt để bạn duyệt kiến trúc trước khi Codex triển khai |
| Bugfix nhỏ, refactor cục bộ | Codex | Nhanh, ít rủi ro side-effect |
| Viết test hàng loạt cho nhiều system | Antigravity | Có thể chạy task nền dài trong khi bạn dùng Codex việc khác |
| Batch xử lý asset (đổi tên, resize, convert) | Antigravity | Có khả năng thao tác đa surface/terminal, phù hợp task lặp |
| Review/QA UI trong browser preview | Antigravity | Có browser control tích hợp |

Gợi ý luồng thực tế: **Antigravity lên plan → bạn duyệt → Codex triển khai chi tiết → Antigravity viết test/QA lại.**

---

## 4. Pipeline Blender → Godot

1. Model/asset gốc lưu ở `assets/art/raw/*.blend`
2. Export ra `.glb` (khuyến nghị hơn `.gltf` rời vì gọn 1 file) vào `assets/art/exported/`
3. Naming convention: `ten-doi-tuong_LOD0.glb` (nếu có nhiều mức chi tiết)
4. Trong Godot: import trực tiếp `.glb`, không chỉnh sửa mesh trong Godot — mọi thay đổi hình học quay lại sửa ở Blender rồi export lại
5. Với low-poly mobile: giữ texture atlas chung, hạn chế số lượng material riêng lẻ để giảm draw call

Nếu muốn tự động hoá, có thể viết Blender Python script (`export.py`) chạy qua `blender --background --python export.py` để batch export — đây là việc rất hợp để giao cho Antigravity chạy task nền.

---

## 5. CI/CD cơ bản — GitHub Actions build Android

File `.github/workflows/build-android.yml` gợi ý luồng: mỗi khi push lên nhánh `main`, tự động build file AAB bằng Godot export template (chạy headless), rồi upload artifact để bạn tải về test hoặc đẩy thẳng lên Play Console (Internal Testing track).

→ Việc setup GitHub Actions cụ thể (kèm keystore signing) cần vài bước riêng — nếu bạn muốn, mình có thể viết chi tiết file YAML này ở lượt sau khi bạn đã chốt cấu trúc project.

---

## 6. Game Design — Cơ chế cốt lõi đã chốt (Tower/Base Defense hậu tận thế)

### 6.1 Thể loại & tổng quan
- Thủ thành tầm xa: base cố định phía dưới màn hình (dọc), quái xuất hiện từ xa tiến về base theo **1 đường cố định mỗi màn**.
- Nhân vật chính dùng vũ khí tầm xa đã có sẵn (không tạo vũ khí mới), nâng cấp qua tiền kiếm được sau mỗi màn.
- Cốt truyện: nhân loại sau thảm họa, kể qua text/hình minh họa tĩnh giữa các chương (chưa cần cutscene động ở MVP).
- Art style đề xuất: low-poly 3D, góc 2.5D cố định, tô phẳng/toon shading, bảng màu hậu tận thế.
- MVP: 15-20 màn.

### 6.2 Hệ thống năng lượng
- Giới hạn số lượt chơi bằng năng lượng (hồi theo thời gian, xem ads hoặc mua để hồi thêm — chi tiết monetize để bổ sung sau).
- **Thua = chơi lại đúng màn đó** (không mất tiến độ campaign, chỉ tốn thêm 1 năng lượng để thử lại).

### 6.3 Hệ thống vũ khí & nâng cấp (ngoài màn, tại hub)
- Nâng cấp diễn ra ở giao diện ngoài màn, dùng tiền kiếm được sau khi thắng màn.
- Hai trục nâng cấp/chỉnh:
  1. **Chỉ số thuần**: damage, tốc bắn, số lượng đạn... (tăng tuyến tính theo cấp nâng)
  2. **Loại vũ khí phù hợp theo màn**: chọn theo 2 trục phân loại —
     - Số mục tiêu: đơn mục tiêu / đa mục tiêu (AOE)
     - Tầm bắn: gần (cận chiến tầm xa) / trung
- **Open item (chốt sau)**: vũ khí có hiệu ứng đặc biệt (burn, slow, stun...) — để dành làm lớp nâng cấp sâu hơn cho giai đoạn sau MVP.

### 6.4 Hệ thống 30 cấp trong 1 màn (core loop chính)
- Mỗi màn gồm **30 cấp**, mỗi cấp là 1 khung thời gian cố định (ví dụ mặc định **15 giây/cấp** — cần playtest để tinh chỉnh theo độ khó thực tế).
- Quái nhả liên tục theo khung thời gian của từng cấp — **nếu người chơi chưa dọn xong quái của cấp hiện tại, quái của cấp kế tiếp vẫn cứ nhả chồng lên** (áp lực dồn tăng dần, không có cơ chế "chờ dọn xong mới next").
- Quy đổi EXP: tiêu diệt đủ số quái quy định (mặc định ~15 quái/cấp) = đủ EXP lên 1 cấp.
- Qua đủ 30 cấp = thắng màn. Base (trụ chính) hết máu tại bất kỳ thời điểm nào = thua ngay lập tức (không cần chờ hết 30 cấp).
- **Open item**: độ khó quái (máu, số lượng, tốc độ) cần tăng dần theo cấp — công thức scaling cụ thể để tinh chỉnh khi có playtest.

### 6.5 Hệ thống hero phụ
- Roster hero phụ **vĩnh viễn** (unlock qua tiến trình chơi ngoài màn) — ví dụ tổng 6 hero.
- Trong 1 lượt chơi màn: mỗi lần người chơi lên cấp (theo hệ thống 6.4), được chọn ngẫu nhiên 1 trong 2 lựa chọn:
  - **Mở 1 hero mới** (random từ những hero đã unlock vĩnh viễn nhưng chưa active trong lượt chơi này)
  - **Nâng cấp 1 hero đang active** lên cấp cao hơn
- Mỗi hero có **trần cấp riêng trong 1 lượt chơi** (ví dụ cấp 15 — cần tinh chỉnh theo balance).
- Số hero active cùng lúc: linh hoạt theo lựa chọn người chơi, **giới hạn cứng tối đa 4 slot** (do giới hạn không gian UI màn hình dọc) — *giả định, cần bạn xác nhận*.
- Tiến độ hero active trong màn **reset khi thua/chơi lại** (theo 6.2).

---

## 7. Phân chia task cụ thể — Codex (chính) vs Antigravity (phụ)

Nguyên tắc: **Codex động vào mọi logic gameplay/core system**. **Antigravity chỉ làm việc không thể phá vỡ game nếu làm sai** — test, asset, docs, CI, mockup tĩnh. Antigravity không được sửa file trong `scripts/systems/` hay `scripts/entities/`.

### 7.1 Codex — Sprint 1: nền tảng core loop

**Tiến độ thực tế (không phải kế hoạch — đã hoàn thành và review kỹ từng file):**
1. ✅ Project scaffold — Antigravity Phase 0
2. ✅ EnergySystem
3. ✅ BaseHealthSystem
4. ✅ Enemy entity (bổ sung, không có trong list gốc — cần thiết trước WaveManager)
5. ✅ WaveManager
6. ✅ LevelSystem
7. ✅ GameState (điều phối thua/thắng/retry — bổ sung, không có trong list gốc, cần thiết để nối các system lại)
8. ⏳ HeroSystem — đang giao
9. ⬜ WeaponSystem
10. ⬜ SaveSystem

Giao lần lượt, mỗi task là 1 nhánh `feature/...` riêng, review xong mới sang task tiếp:

1. **Project scaffold** — dựng cấu trúc thư mục theo mục 1, tạo các autoload rỗng (`GameState`, `EventBus`, `EnergySystem`, `WaveManager`, `LevelSystem`, `HeroSystem`, `SaveSystem`).
2. **EnergySystem** — quản lý số năng lượng hiện tại, max, thời gian hồi/1 đơn vị, hàm `spend_energy()` và `can_play()`. Chưa cần UI, chỉ logic + signal `energy_changed`.
3. **BaseHealthSystem** — máu base, hàm `take_damage(amount)`, phát signal `base_defeated` khi máu = 0.
4. **WaveManager** — spawn quái theo khung thời gian cố định/cấp (mặc định 15s), quái cấp sau tiếp tục spawn nếu cấp trước chưa dọn xong (không chờ). Input: enemy data theo cấp (data-driven, đọc từ resource `.tres` để dễ balance sau).
5. **LevelSystem (trong màn)** — track số quái đã giết, tính EXP, trigger `level_up` khi đủ ngưỡng (mặc định 15 quái/cấp), tối đa cấp 30 → phát signal `stage_cleared`.
6. **HeroSystem** — khi nhận `level_up`: random chọn "mở hero mới" hoặc "nâng cấp hero active", giới hạn tối đa 4 slot active, mỗi hero có trần cấp riêng (mặc định 15).
7. **WeaponSystem** — áp dụng chỉ số đã nâng cấp (ngoài màn) vào vũ khí trong trận: damage, tốc bắn, loại mục tiêu (đơn/đa), tầm (gần/trung).
8. **Retry flow** — khi `base_defeated`: reset toàn bộ state trong màn (cấp, EXP, hero active) về đầu, giữ nguyên progress ngoài màn (vàng, upgrade vĩnh viễn).
9. **SaveSystem** — lưu/đọc: vàng, cấp nâng vũ khí, roster hero đã unlock vĩnh viễn, màn đã qua.

**Mẫu prompt để giao task 2 cho Codex:**
> "Trong project Godot 4 này, đọc `AGENTS.md` trước. Tạo autoload `EnergySystem` (`scripts/systems/energy_system.gd`) quản lý năng lượng: `max_energy` (mặc định 5), `current_energy`, thời gian hồi 1 đơn vị (mặc định 20 phút, dùng biến để dễ chỉnh), hàm `spend_energy() -> bool` (trả false nếu không đủ), hàm `can_play() -> bool`, và signal `energy_changed(current, max)`. Viết kèm test đơn giản trong `tests/` kiểm tra hồi năng lượng theo thời gian."

### 7.2 Antigravity — task hỗ trợ, không đụng logic core

**Phase 0 (làm đầu tiên, trước cả Codex):** dựng khung dự án theo mục 1.1/1.2 — tạo folder, file rỗng có TODO, Resource schema, data mẫu, đăng ký autoload.

**Mẫu prompt giao Phase 0 cho Antigravity:**
> "Đọc `AGENTS.md`, đặc biệt phần **Definition of Done**. Nhiệm vụ: dựng khung dự án Godot 4 theo đúng cấu trúc thư mục ở mục 1 trong file thiết kế đính kèm. Chỉ tạo file rỗng với dòng comment đầu file dạng `# TODO(Codex): xem mục 7.1 task N`, KHÔNG viết thân hàm logic. Tạo 3 file Resource schema (`enemy_data.gd`, `weapon_data.gd`, `hero_data.gd`) đúng field đã liệt kê ở mục 1.2. Tạo 2-3 file `.tres` mẫu cho mỗi loại (enemy/weapon/hero) với số liệu giả bất kỳ chỉ để test khung chạy được. Đăng ký các autoload vào `project.godot` (KHÔNG đụng phần export/signing). Lên plan liệt kê toàn bộ file sẽ tạo trước, chờ tôi duyệt rồi mới thực thi. **Sau khi làm xong, bắt buộc dán đủ 4 mục Definition of Done — danh sách file, đối chiếu từng yêu cầu ✅/❌, xác nhận đã đọc lại nội dung từng file, và nêu rõ phần nào bạn tự quyết định. Không được nói 'đã xong' nếu thiếu bất kỳ mục nào.**"

**Task tiếp theo, sau khi Codex code xong từng phần:**

1. **Viết unit test** cho các system Codex đã hoàn thành (dựa vào signal/hàm public đã có, không tự đoán logic bên trong).
2. **Batch export asset** — chạy Blender script (`.blend` → `.glb`) hàng loạt, đặt tên đúng convention ở mục 4.
3. **Dựng mockup UI tĩnh** — màn chọn map, hub nâng cấp vũ khí, HUD trong trận (chưa gắn logic, chỉ layout để Codex tích hợp sau).
4. **Setup GitHub Actions CI** — build Android APK tự động mỗi lần push (khung sườn, chưa cần ký release).
5. **QA browser preview** — dùng khả năng điều khiển browser của Antigravity để click-test UI, ghi lại lỗi hiển thị (không tự sửa code, chỉ báo cáo).
6. **Sinh/cập nhật docs** — `changelog.md` sau mỗi PR merge, tóm tắt thay đổi.
7. **Dọn code style** — format, đặt tên biến theo convention *sau khi* Codex đã merge — không đổi logic, chỉ style pass.

**Mẫu prompt giao task test cho Antigravity:**
> "Đọc `AGENTS.md`. Không sửa bất kỳ file nào trong `scripts/systems/` hoặc `scripts/entities/`. Nhiệm vụ: viết test cho `EnergySystem` (đã có ở `scripts/systems/energy_system.gd`) — test các hàm public `spend_energy()`, `can_play()`, và việc hồi năng lượng theo thời gian. Lên plan trước, liệt kê case test sẽ viết, chờ tôi duyệt rồi mới code. **Sau khi làm xong, bắt buộc dán đủ 4 mục Definition of Done trong `AGENTS.md`.**"

---

## 8. Checklist trước khi release lên CH Play (bản nâng cấp so với game đầu)

- [ ] Test trên ít nhất 2 độ phân giải màn hình khác nhau
- [ ] Kiểm tra save/load không mất dữ liệu khi thoát app đột ngột
- [ ] Đặt version code/version name tăng đúng chuẩn semver
- [ ] Privacy policy + target API level đáp ứng yêu cầu mới nhất của Google Play
- [ ] Test trên thiết bị thật (không chỉ emulator), tối thiểu 1 máy cấu hình thấp
- [ ] Có Internal Testing track trước khi Production

---

## 9. Trước khi giao việc thật — bạn cần chốt/chuẩn bị sẵn

Vài thứ nếu không chốt trước, agent sẽ tự đoán và có thể đoán sai, tốn công sửa lại:

- [ ] **Repo GitHub**: đã tạo chưa, hay để Antigravity tạo repo mới ở Phase 0?
- [ ] **Godot version cụ thể**: 4.2 / 4.3 / 4.4... (ghi rõ vào `AGENTS.md` mục "Bối cảnh dự án", tránh lệch API giữa agent và máy bạn)
- [ ] **Tên gói ứng dụng (package name)**: ví dụ `com.yourname.gamename` — nên chốt sớm vì **không đổi được sau khi đã publish lên CH Play**
- [ ] **Keystore**: dùng lại từ game đầu (nếu update cùng dev account) hay tạo keystore mới — quyết định này ảnh hưởng tới CI/CD ký release sau này
- [ ] **Tên game chính thức + icon tạm** — để Antigravity điền vào `project.godot`/README khi scaffold, tránh để placeholder rồi quên đổi
- [ ] **Ai duyệt PR**: chỉ mình bạn duyệt, hay cho phép agent tự merge nhánh nhỏ (test, docs) không cần chờ?

Sau khi có đủ mấy điểm này, bạn có thể giao thẳng Phase 0 cho Antigravity trước, chờ nó xong rồi mới đưa Sprint 1 cho Codex — đúng thứ tự đã note ở mục 1.1.

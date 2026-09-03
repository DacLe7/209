# Changelog

Tất cả các thay đổi đáng chú ý của dự án sẽ được ghi nhận tại file này.

## [Enemy View Pure Node2D Visual] - 2026-09-03
### Đã thay đổi
- Bỏ script `enemy.gd` khỏi root của `scenes/entities/enemy_view.tscn`, biến scene thành `Node2D` thuần túy chứa 2 polygon visual `Body` và `Core`.
- Cập nhật `scripts/core/battle_arena.gd`: bỏ lệnh `visual.set_process(false)` khi đính kèm visual vào node quái do `WaveManager` sinh ra.

## [Enemy Death Cleanup] - 2026-09-03
### Đã thay đổi
- Enemy phát `died` trước khi tự `queue_free()` khi HP chạm 0, để WaveManager nhận relay trước khi node bị xoá.
- Thêm unit test headless xác nhận enemy được xếp lịch xoá sau khi chết.

## [Main Gameplay Loop Integration] - 2026-09-03
### Đã thêm
- Triển khai scene trận đấu `scenes/core/battle_arena.tscn` và `scripts/core/battle_arena.gd`: gán đường đi `path_waypoints` cho `WaveManager`, tự động gắn visual `enemy_view.tscn` khi quái spawn, hiển thị `base_view.tscn`, tích hợp HUD và Run Result Overlay, bắt đầu trận với `GameState.start_stage()`.
- Triển khai scene điều phối luồng chơi `scenes/core/main.tscn` và `scripts/core/main.gd`: boot mặc định vào `map_selection`, chuyển cảnh sang `battle_arena` khi xuất kích và chuyển về lại `map_selection` khi hoàn thành/kết thúc trận.
- Cấu hình `run/main_scene="res://scenes/core/main.tscn"` trong `project.godot`.
- Thêm bộ test headless `tests/main_flow_test.gd` và runner `tests/run_main_flow_tests.gd`.

## [Wave Enemy Spawn Signal] - 2026-09-03
### Đã thay đổi
- `WaveManager.enemy_spawned` phát instance Enemy ngay sau khi được thêm vào WaveManager, để scene/UI gắn visual khi spawn.
- Thêm unit test headless xác nhận số signal khớp số quái spawn trong một lần cập nhật thời gian.

## [Visual Placeholder Scenes] - 2026-09-03
### Đã thêm
- Tạo scene placeholder `scenes/entities/enemy_view.tscn`: Root `Node2D` gắn script `enemy.gd` (không sửa file này) cùng hình khối `Polygon2D` màu đỏ làm thân quái tạm thời.
- Tạo scene placeholder `scenes/core/base_view.tscn`: Root `Node2D` chứa hình khối `Polygon2D` màu xanh lam lớn cùng nhãn "BASE" làm trụ chính tạm thời.
- Cập nhật unit test khởi tạo scene trong `tests/ui_system_test.gd`.

## [Weapon Upgrade Hub Binding] - 2026-09-03
### Đã thêm
- Bind `weapon_upgrade_hub.gd` vào `WeaponSystem` autoload: thực hiện `WeaponSystem.upgrade_weapon()`, hiển thị chỉ số combat thực tế qua `get_weapon_stats()`.
- Cập nhật hiển thị vàng từ `WeaponSystem.current_gold`, xử lý các trạng thái nút bấm: "MAX CẤP" khi đạt tối đa, "KHÔNG ĐỦ VÀNG" khi thiếu tiền.
- Lắng nghe signal `WeaponSystem.weapon_upgraded` để cập nhật lại UI tức thời.
- Kết nối signal `HeroSystem.run_reset` vào `BattleHUD.reset_hero_slots()` trong `battle_hud.gd` để tự động trả các slot hero về `[Trống]`.
- Cập nhật unit test `_test_weapon_hub_interactions` và `_test_hud_hero_slot_bindings` trong `tests/ui_system_test.gd`.

## [Hero Run Reset Signal] - 2026-09-03
### Đã thêm
- HeroSystem phát `run_reset` sau khi xoá hero active, để UI đồng bộ khi bắt đầu hoặc retry lượt chơi.
- Thêm unit test headless cho signal reset.

## [Weapon System] - 2026-09-03
### Đã thêm
- Triển khai roster vũ khí meta-progression, nâng cấp bằng gold và chỉ số combat tăng tuyến tính theo cấp.
- Thêm unit test headless cho roster, nâng cấp, chi phí, signal và chỉ số đã scale.

## [Hero Slots Binding & Run Result Overlay] - 2026-09-03
### Đã thêm
- Hero Slots Binding: Kết nối 4 slot hero trong `battle_hud.tscn` và `battle_hud.gd` với `HeroSystem.hero_activated` và `HeroSystem.hero_upgraded`. Hiển thị tên hero kèm cấp độ khi active, giữ `[Trống]` khi chưa chiếm slot và hỗ trợ reset khi retry.
- Run Result Overlay: Tạo scene `scenes/ui/run_result_overlay.tscn` và script `scripts/ui/run_result_overlay.gd` lắng nghe `GameState.run_failed` (hiện "THẤT BẠI" + nút [THỬ LẠI] gọi `GameState.retry_stage()`) và `GameState.run_completed` (hiện "HOÀN THÀNH MÀN" + nút [VỀ BẢN ĐỒ] emit `back_to_map_requested`).
- Unit Tests: Mở rộng `tests/ui_system_test.gd` kiểm tra toàn bộ luồng bind hero slots (active, upgrade, reset) và trạng thái hiển thị, tương tác của RunResultOverlay.

## [CI/CD & UI Mockups] - 2026-09-03
### Đã thêm
- CI/CD: Cập nhật `.github/workflows/build-android.yml` và tạo `export_presets.cfg` cho Android headless debug export tự động trên Godot 4.7.2-stable, upload artifact APK.
- UI Mockup: Triển khai 3 scene UI (`map_selection.tscn`, `weapon_upgrade_hub.tscn`, `battle_hud.tscn`) cùng controller scripts trong `scripts/ui/`.
- Signal Binding: HUD trong trận kết nối trực tiếp với 3 signal ổn định (`BaseHealthSystem.health_changed`, `EnergySystem.energy_changed`, `LevelSystem.level_up`).
- Unit Tests: Bổ sung bộ test headless `tests/ui_system_test.gd` và `tests/run_ui_system_tests.gd` kiểm tra khởi tạo scene, tương tác và signal binding.

## [Hero System] - 2026-09-03
### Đã thêm
- Triển khai roster hero nạp tự động từ resource, kích hoạt/nâng cấp theo level-up và reset state theo lượt chơi.
- GameState reset hero active khi bắt đầu hoặc retry màn.
- Thêm unit test headless cho roster, giới hạn slot, activation/upgrade và reset retry.

## [Wave Start Ownership] - 2026-09-03
### Đã thay đổi
- WaveManager không còn tự bắt đầu wave trong `_ready()`; GameState là nơi điều phối thời điểm bắt đầu màn.
- Thêm test xác nhận WaveManager khởi tạo ở trạng thái chưa có batch và tier 0.

## [Game State] - 2026-09-03
### Đã thêm
- Triển khai điều phối thua/thắng màn: dừng wave, phát signal kết quả và hỗ trợ bắt đầu/retry lượt chơi.
- Thêm unit test headless cho nhánh thua, nhánh thắng và retry stage.

## [Level System] - 2026-09-03
### Đã thêm
- Triển khai EXP và cấp trong màn, giữ EXP dư, phát level-up và stage clear ở cấp 30.
- Reset tiến độ level tự động khi trụ bị phá hủy.
- Thêm unit test headless cho EXP dư, stage clear một lần và reset khi thua.

## [Wave Manager] - 2026-09-03
### Đã thêm
- Triển khai lịch spawn 30 tier với các batch spawn hoạt động đồng thời và boss ở tier cuối.
- Relay tín hiệu quái chết/chạm trụ đến hệ thống EXP và máu trụ.
- Thêm unit test headless cho lịch spawn, batch chồng đợt, relay signal và giới hạn tier 30.

## [Enemy Entity] - 2026-09-02
### Đã thêm
- Triển khai entity quái theo waypoint, khởi tạo chỉ số từ `EnemyData`, nhận sát thương và phát signal chết/chạm trụ.
- Thêm unit test headless cho dữ liệu khởi tạo, sát thương/chết và di chuyển waypoint.

## [Base Health System] - 2026-09-02
### Đã thêm
- Triển khai `BaseHealthSystem`: quản lý máu trụ, sát thương, retry reset, signal cập nhật máu và signal thua màn một lần.
- Thêm unit test headless cho sát thương, giới hạn máu, signal và reset retry.

## [Energy System] - 2026-09-02
### Đã thêm
- Triển khai `EnergySystem`: giới hạn năng lượng, tiêu năng lượng, hồi 1 điểm mỗi 20 phút và signal cập nhật năng lượng.
- Thêm unit test headless cho việc tiêu năng lượng, khả năng chơi, hồi năng lượng theo thời gian và signal `energy_changed`.

## [Phase 0: Project Scaffold] - 2026-09-02
### Đã thêm
- Dựng cây thư mục chuẩn cho Godot 4.7 theo `AI-Agent-Game-Dev-Setup.md`.
- Tạo file cấu hình `project.godot` và đăng ký đủ 9 Autoload Singleton: `GameState`, `EventBus`, `EnergySystem`, `BaseHealthSystem`, `WaveManager`, `LevelSystem`, `HeroSystem`, `WeaponSystem`, `SaveSystem`.
- Tạo các Resource schema trong `scripts/resources/`:
  - `EnemyData` (`enemy_data.gd`)
  - `WeaponData` (`weapon_data.gd`)
  - `HeroData` (`hero_data.gd`)
- Tạo các file dữ liệu mẫu `.tres` trong `data/`:
  - `enemy_grunt.tres`, `enemy_boss_stage1.tres`
  - `weapon_rifle_single_mid.tres`, `weapon_shotgun_multi_close.tres`
  - `hero_commander.tres`, `hero_sniper.tres`
- Tạo các file rỗng đánh dấu `# TODO(Codex): ...` cho các hệ thống trong `scripts/autoload/` và `scripts/systems/`.
- Thêm file quy tắc `AGENTS.md`, `README.md`, `docs/design-doc.md`, và `.github/workflows/build-android.yml`.

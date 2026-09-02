# Changelog

Tất cả các thay đổi đáng chú ý của dự án sẽ được ghi nhận tại file này.

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

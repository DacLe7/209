# Changelog

Tất cả các thay đổi đáng chú ý của dự án sẽ được ghi nhận tại file này.

## [Upgrade Choice Overlay] - 2026-09-10
### Đã thêm
- Tạo scene `scenes/ui/upgrade_choice_overlay.tscn` và script `scripts/ui/upgrade_choice_overlay.gd`: overlay toàn màn hình với nền mờ (`DimBackground`) chặn tương tác, mặc định ẩn, chế độ `process_mode = PROCESS_MODE_ALWAYS`.
- Lắng nghe signal `HeroSystem.upgrade_choices_ready`: tự động sinh động 2-3 thẻ nâng cấp (`PanelContainer` trong `HBoxContainer`) hiển thị rõ ràng nhãn hành động ("🆕 MỞ MỚI" màu xanh / "⬆ NÂNG CẤP" màu vàng cam), tên hiển thị của hero, thông tin cấp độ hiện tại và kế tiếp ("Cấp %d ➔ Cấp %d"), cùng nút [CHỌN].
- Tạm dừng game (`get_tree().paused = true`) khi overlay hiển thị để người chơi tập trung lựa chọn, tự động khôi phục (`get_tree().paused = false`) khi hoàn tất lựa chọn hoặc thoát scene.
- Bấm chọn 1 thẻ gọi trực tiếp `HeroSystem.choose_upgrade(index)`, phát signal `upgrade_chosen(option_index)`, và tự động đóng overlay (hoặc tiếp tục hiển thị đợt nâng cấp tiếp theo nếu còn hàng đợi level-up).
- Lắng nghe `HeroSystem.run_reset`: tự động đóng overlay và gỡ tạm dừng khi trận đấu reset.
- Tích hợp node `UpgradeChoiceOverlay` vào `UILayer` của `scenes/core/battle_arena.tscn`, đồng bộ tham chiếu và kết nối signal trong `scripts/core/battle_arena.gd`.
- Bổ sung unit test `_test_upgrade_choice_overlay_lifecycle` trong `tests/main_flow_test.gd`: xác thực toàn diện vòng đời overlay, số lượng thẻ tạo động, nội dung nhãn, phát signal chọn thẻ và xử lý dọn dẹp khi reset run.

## [Player-Selected Hero Upgrades] - 2026-09-10
### Đã thay đổi
- HeroSystem phát danh sách thẻ activate/upgrade khi lên cấp thay vì tự áp dụng ngẫu nhiên.
- Level-up đến khi đang chọn được xếp hàng; request không còn candidate bị bỏ qua để không chặn hàng đợi.
- Thêm test headless cho format options, chọn thẻ, queue, reset và trường hợp không có candidate.

## [Rectangular RangeIndicator & Secondary Hero Bullet Tracers] - 2026-09-10
### Đã thêm
- Cập nhật `scripts/core/range_indicator.gd`: chuyển từ vẽ vòng tròn bán kính sang vẽ hình chữ nhật qua `draw_rect` với 2 thuộc tính `half_width` và `half_height` (tâm tại `(0, 0)`, kích thước `2 * half_width` x `2 * half_height`).
- Cập nhật `scripts/core/battle_arena.gd`: hàm `_update_range_indicator()` đọc đúng 2 key `range_half_width` và `range_half_height` từ `WeaponSystem.get_weapon_stats()` và gán vào `half_width`/`half_height` của `RangeIndicator`.
- Kết nối signal `weapon_fired` của mỗi instance `SecondaryHero` vào hàm vẽ tia đạn chung `_on_main_hero_weapon_fired` trong `battle_arena.gd`, và ngắt kết nối an toàn khi reset run.
- Cập nhật `tests/main_flow_test.gd`: gỡ 2 comment TODO, khôi phục và kiểm tra chính xác kích thước half-extent mới (`shotgun_breach`: `180x220`, `rifle_standard`: `280x450`), đồng thời kiểm thử signal `weapon_fired` của `SecondaryHero` tạo tia đạn thành công.

## [Secondary Hero Arena Spawning & Lifecycle] - 2026-09-10
### Đã thêm
- Bổ sung cấu hình 4 slot bố cục chữ V quanh MainHero trong `scripts/core/battle_arena.gd`: Slot 0 `(-80, -45)`, Slot 1 `(80, -45)`, Slot 2 `(-45, -90)`, Slot 3 `(45, -90)` không chồng lấn lên MainHero hay BaseView.
- Lắng nghe `HeroSystem.hero_activated`: tự động tạo instance `SecondaryHero.new()`, khởi tạo với `HeroData` tương ứng và level, đặt vị trí theo slot, gán visual 2 `Polygon2D` (Body vàng cam `Color(0.95, 0.65, 0.15, 1.0)`, Core vàng sáng `Color(1.0, 0.92, 0.45, 1.0)`) và thêm vào scene.
- Lắng nghe `HeroSystem.hero_upgraded`: cập nhật `set_level(new_level)` cho instance hero phụ tương ứng.
- Lắng nghe `HeroSystem.run_reset`: giải phóng toàn bộ instance `SecondaryHero` đang hoạt động.
- Đồng bộ tự động các hero phụ đã kích hoạt sẵn từ trước lúc `BattleArena._ready()`.
- Bổ sung unit test `_test_secondary_hero_lifecycle` trong `tests/main_flow_test.gd` xác thực toàn diện vòng đời, vị trí slot và visual.

## [Rectangular Combat Range] - 2026-09-10
### Đã thay đổi
- WeaponData và HeroData thay bán kính tròn bằng `range_half_width`/`range_half_height`; data mẫu và WeaponSystem đã dùng API mới.
- MainHero và SecondaryHero kiểm tra vùng bắn chữ nhật, vẫn ưu tiên mục tiêu SINGLE gần nhất trong vùng.
- Tạm vô hiệu hoá hai assertion radius cũ của RangeIndicator, chờ Antigravity chuyển visual sang hình chữ nhật.

## [Enemy Base Reach Cleanup] - 2026-09-10
### Đã sửa
- Enemy phát `reached_base` trước rồi tự `queue_free()` khi đến base, ngăn quái tích tụ vĩnh viễn tại trụ.
- Thêm assertion headless xác nhận node đã được xếp lịch xoá sau khi chạm base.

## [Secondary Hero Weapon Fired Signal] - 2026-09-10
### Đã thêm
- SecondaryHero phát `weapon_fired(from, to)` cho từng mục tiêu nhận sát thương, gồm từng mục tiêu MULTI.
- Mở rộng test headless xác nhận số lần và toạ độ signal cho cả SINGLE/MULTI.

## [Bullet Tracer Effects & Visibility Enhancement] - 2026-09-09
### Đã thêm
- Thêm node container `Tracers` (`Node2D`, `z_index = 5`) trong `scenes/core/battle_arena.tscn` để chứa các tia đạn, đảm bảo hiển thị rõ trên nền, trên hero và quái.
- Cập nhật `scripts/core/battle_arena.gd`: lắng nghe signal `main_hero.weapon_fired(from, to)`, tạo tia đạn `Line2D` tức thì với độ dày `4.5px`, màu sáng xanh hero `Color(0.65, 1.0, 0.75, 0.9)`, bo tròn 2 đầu `LINE_CAP_ROUND`.
- Quản lý vòng đời tia đạn tập trung qua `_process(delta)` với thời lượng tồn tại `0.25s` (tăng từ 0.12s để mắt thường quan sát rõ ràng), giải phóng node và remove khỏi tree ngay khi hết hạn, dọn sạch khi `_exit_tree()`.
- Bổ sung unit test `_test_bullet_tracer_lifecycle` trong `tests/main_flow_test.gd`: kiểm tra việc tạo `Line2D`, thuộc tính visual, toạ độ, thời lượng sống 0.25s, xử lý multi-shot đồng thời và giải phóng sạch sẽ khi thoát scene.

## [Main Hero Dynamic Range Indicator] - 2026-09-09
### Đã thêm
- Tạo script `scripts/core/range_indicator.gd` kế thừa `Node2D`, vẽ vòng tròn tầm bắn bằng code `_draw()` (`draw_circle` màu mờ + `draw_arc` viền ngoài) với thuộc tính `radius` tự động gọi `queue_redraw()`.
- Thêm node con `RangeIndicator` (`z_index = -1`) vào `MainHero` trong `scenes/core/battle_arena.tscn` để hiển thị phạm vi tầm bắn dưới thân hero/quái và trên nền arena.
- Cập nhật `scripts/core/battle_arena.gd`: đồng bộ bán kính `radius` từ `WeaponSystem.get_weapon_stats()` khi khởi tạo `_ready()` và cập nhật động qua signal `weapon_equipped`.
- Mở rộng unit test trong `tests/main_flow_test.gd`: kiểm tra tồn tại node `RangeIndicator`, tầng `z_index`, bán kính khởi tạo theo vũ khí ban đầu và tự động cập nhật bán kính khi đổi sang vũ khí khác.

## [Main Hero Weapon Fired Signal] - 2026-09-09
### Đã thêm
- MainHero phát `weapon_fired(from, to)` cho từng mục tiêu thực sự nhận sát thương, gồm từng mục tiêu của đòn MULTI.
- Bổ sung test headless cho số lần và toạ độ signal ở đòn SINGLE/MULTI.

## [Random Enemy Lanes] - 2026-09-09
### Đã thay đổi
- WaveManager thay shared path bằng lane dọc ngẫu nhiên riêng cho từng quái, với biên X và Y cấu hình được.
- BattleArena xoá PathLine zíc zắc lúc runtime vì nó không còn phản ánh đường đi gameplay.
- Cập nhật test spawn, GameState và main flow theo API lane mới.

## [Secondary Hero Combat] - 2026-09-08
### Đã thêm
- HeroData có chỉ số combat; Commander Sarah đánh đa mục tiêu tầm trung, Ghost Sniper đánh đơn mục tiêu tầm xa.
- SecondaryHero tự tìm mục tiêu và bắn theo cooldown; damage tăng luỹ thừa theo level tạm thời trong màn.
- Thêm kiểm thử headless cho nhịp bắn, SINGLE/MULTI, giới hạn tầm và tăng cấp.

## [Stage Waypoints & Stage 1 Zigzag Path] - 2026-09-08
### Đã thêm
- Thêm từ điển `STAGE_PATHS` trong `scripts/core/battle_arena.gd` quản lý các bộ waypoints theo `stage_id` (màn 1 đến 4).
- Triển khai đường đi zíc zắc uốn lượn tự nhiên 6 điểm cho Màn 1 trên khung hình 720x1280 từ đỉnh `(360, 80)` đến căn cứ `(360, 1060)`.
- Bổ sung `@export var stage_id: int = 1` cho `BattleArena`, tự động đồng bộ bộ waypoints tương ứng và gán cho `WaveManager`, `PathLine` và `BaseView`.
- Cập nhật `scripts/core/main.gd`: truyền thực tế `stage_id` từ `start_battle(stage_id)` xuống `BattleArena.stage_id`.
- Cập nhật `scenes/core/battle_arena.tscn`: đồng bộ các điểm `points` của `PathLine` theo 6 toạ độ zíc zắc Màn 1.
- Mở rộng unit test trong `tests/main_flow_test.gd`: kiểm tra kích thước 6 waypoints, toạ độ đầu/cuối, vị trí `BaseView` và tính năng chuyển đổi đường đi theo `stage_id`.

## [Main Menu & Boot Routing] - 2026-09-05
### Đã thêm
- Tạo scene `scenes/ui/main_menu.tscn` và script `scripts/ui/main_menu.gd` cho màn hình mở đầu (720x1280): hiển thị tên game "PostApocDefense", nút [BẮT ĐẦU] phát signal `play_pressed` và nút placeholder [CÀI ĐẶT] (disabled).
- Cập nhật `scripts/core/main.gd`: khởi động boot vào `MainMenu` trước, lắng nghe `play_pressed` để chuyển sang `MapSelection`.
- Cập nhật kiểm thử tự động trong `tests/main_flow_test.gd` và `tests/ui_system_test.gd` cho luồng khởi động và chuyển cảnh mới.

## [Save System] - 2026-09-05
### Đã thêm
- SaveSystem lưu và khôi phục vàng, cấp vũ khí và vũ khí đang trang bị tại `user://save_data.json` bằng JSON có version.
- Dữ liệu hỏng, field không hợp lệ và ID vũ khí đã bị loại bỏ được xử lý phòng thủ, không ghi đè file hỏng lúc khởi động.
- Autosave sau các signal thay đổi vàng, nâng cấp và trang bị vũ khí; thêm bộ test headless độc lập.

## [Weapon Upgrade Hub Gold Exploit Fix] - 2026-09-05
### Đã sửa
- Xóa bỏ logic placeholder tự gán `current_gold = 1000` trong `_ready()` và `_show_weapon()` của `scripts/ui/weapon_upgrade_hub.gd`, ngăn chặn lỗ hổng nhận 1000 vàng miễn phí vô hạn khi tiêu cạn vàng.
- Kết nối signal `WeaponSystem.gold_changed` trong `weapon_upgrade_hub.gd` để tự động cập nhật số dư vàng khi nhận thưởng từ gameplay.
- Chuyển fixture thiết lập vàng test vào `tests/ui_system_test.gd`, bổ sung kiểm tra chống hồi quy cho số dư vàng ban đầu và signal `gold_changed`.

## [Stage Completion Gold Reward] - 2026-09-05
### Đã thêm
- GameState thưởng cố định 150 vàng đúng một lần khi hoàn thành màn, trước khi phát `run_completed`.
- WeaponSystem bổ sung `add_gold()` và signal `gold_changed` để UI và SaveSystem tái sử dụng.
- Thêm kiểm tra headless cho tín hiệu vàng, thưởng thắng màn một lần và retry không tự thưởng vàng.

## [Weapon Equip Binding & Hero Sync] - 2026-09-05
### Đã thêm
- Kết nối nút "TRANG BỊ" trong `scripts/ui/weapon_upgrade_hub.gd` với `WeaponSystem.set_equipped_weapon()`, lắng nghe signal `weapon_equipped` để cập nhật trạng thái nút ("ĐANG TRANG BỊ" / "TRANG BỊ").
- Đồng bộ vũ khí trang bị từ `WeaponSystem` sang `MainHero` trong `scripts/core/battle_arena.gd` tại `_ready()` và qua signal `weapon_equipped`.
- Bổ sung unit test headless trong `tests/ui_system_test.gd` và `tests/main_flow_test.gd`.

## [Main Hero Visual Polygons] - 2026-09-05
### Đã thêm
- Thêm visual gồm 2 Polygon2D (`Body` hình thoi xanh lá và `Core` xanh mint sáng) trực tiếp vào node `MainHero` trong `scenes/core/battle_arena.tscn`.
- Thêm kiểm tra khẳng định trong `tests/main_flow_test.gd` đảm bảo `MainHero` có đủ 2 node visual `Body` và `Core` mang màu sắc xanh lá.

## [Equipped Weapon State] - 2026-09-05
### Đã thêm
- WeaponSystem lưu vũ khí đang trang bị, hỗ trợ chọn vũ khí hợp lệ và phát signal cập nhật.
- Thêm unit test headless cho equip thành công/thất bại và signal.

## [Main Hero Combat] - 2026-09-05
### Đã thêm
- Thêm range data cho vũ khí và MainHero tự động tấn công quái theo fire rate, target type và range.
- WaveManager cung cấp danh sách quái active cho combat.
- Thêm unit test headless cho nhịp bắn, target đơn/đa và giới hạn tầm bắn.

## [Battle Arena Z-Index Layering Fix] - 2026-09-05
### Đã sửa
- Gán `z_index = -10` cho node `Background` trong `scenes/core/battle_arena.tscn` để luôn vẽ ở lớp dưới cùng, không che lấp quái sinh ra từ autoload `WaveManager`.
- Gán `z_index = -5` cho node `PathLine` trong `scenes/core/battle_arena.tscn` để đường đi hiển thị trên nền nhưng nằm dưới quái và trụ căn cứ (`z_index = 0`).
- Thêm kiểm tra khẳng định phân tầng `z_index` trong `tests/main_flow_test.gd`.

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

# Game Design Document — Tower/Base Defense Hậu Tận Thế

## 1. Thể loại & Tổng quan
- **Thể loại**: Thủ thành tầm xa (Tower / Base Defense), màn hình dọc, đồ họa low-poly 3D góc nhìn 2.5D cố định.
- **Bối cảnh**: Hậu tận thế sau thảm họa, base cố định ở đáy màn hình, kẻ địch tiến về base theo 1 đường cố định mỗi màn.
- **Nhân vật chính**: Điều khiển hệ thống vũ khí tầm xa có sẵn, nâng cấp thông qua tiền vàng kiếm được sau mỗi trận.
- **Quy mô MVP**: 15–20 màn chơi.

## 2. Hệ thống Năng lượng (Energy System)
- Giới hạn lượt chơi qua thanh năng lượng (mặc định tối đa 5 đơn vị, hồi 20 phút / đơn vị).
- **Quy tắc thua**: Người chơi thua thì chơi lại đúng màn đó (không mất tiến độ campaign, chỉ tốn 1 năng lượng để thử lại).

## 3. Hệ thống Vũ khí & Nâng cấp (Hub ngoài màn)
- Nâng cấp bằng tiền vàng nhận được khi hoàn thành màn.
- Hai trục phát triển chính:
  1. **Chỉ số thuần**: Sát thương (damage), tốc độ bắn (fire rate), chi phí nâng cấp theo đường cong lũy tiến.
  2. **Loại vũ khí**:
     - Số mục tiêu: Đơn mục tiêu (Single) / Đa mục tiêu (Multi / AOE).
     - Tầm bắn: Tầm gần (Close) / Tầm trung (Mid).
- *(Giai đoạn sau MVP)*: Thêm hiệu ứng đặc biệt (burn, slow, stun...).

## 4. Hệ thống 30 Cấp trong trận (Core Loop)
- Mỗi màn gồm **30 cấp độ**, mỗi cấp có khung thời gian cố định (mặc định 15 giây/cấp).
- Quái nhả liên tục theo thời gian từng cấp. **Nếu chưa dọn xong quái của cấp trước, quái cấp tiếp theo vẫn spawn chồng lên** (tạo áp lực tăng dần).
- Giết đủ số quái quy định (mặc định ~15 quái/cấp) = đủ EXP lên 1 cấp.
- Điều kiện thắng: Vượt qua đủ 30 cấp.
- Điều kiện thua: Base chính hết máu tại bất kỳ thời điểm nào → thua ngay lập tức.

## 5. Hệ thống Hero phụ (Hero System)
- Roster hero vĩnh viễn (unlock qua tiến trình chơi ngoài màn, ví dụ ban đầu có 6 hero).
- Trong 1 lượt chơi: Mỗi khi người chơi lên cấp, chọn ngẫu nhiên 1 trong 2 lựa chọn:
  - Mở 1 hero mới (random từ roster đã unlock nhưng chưa kích hoạt trong trận này).
  - Nâng cấp 1 hero đang kích hoạt lên cấp cao hơn.
- Giới hạn:
  - Tối đa **4 slot hero active** cùng lúc trong trận.
  - Mỗi hero có trần cấp trong trận riêng (mặc định cấp 15).
  - Tiến độ hero active trong trận sẽ reset về đầu khi thua/chơi lại.

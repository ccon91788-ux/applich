# LifeSync – Lịch, nhắc nhở & quản lý tài chính (offline)

Ứng dụng Flutter/Android, dữ liệu lưu cục bộ bằng SQLite, không cần tài khoản hay Internet.

## Tính năng
- **Lịch**: xem tháng / tuần / ngày, Hôm nay, nhảy tới ngày, lịch âm (bật/tắt), sự kiện có giờ bắt đầu - kết thúc, nhắc trước (đúng giờ … 1 ngày), lặp ngày/tuần/tháng/năm (lặp thật), thông báo âm thanh + rung
- **Tài chính**: thu/chi, danh mục tự nhập, tiền lưu số nguyên VND (`50,000 ₫`), tìm kiếm, Nhập nhanh tiếng Việt (luôn có màn hình xác nhận)
- **Ngân sách tháng**: thanh tiến độ, còn lại, cảnh báo 80/90/100% (mỗi mức một lần mỗi tháng), bật/tắt, đặt lại
- **Hóa đơn định kỳ**: hiện trên lịch, nhắc 8:00 ngày đến hạn, "Đã thanh toán" tự tạo giao dịch chi + dời sang tháng sau, chống trả trùng một kỳ
- **Mục tiêu tiết kiệm**: thanh tiến độ %, thêm/rút tiền, sửa/xóa, hạn chót và số tiền cần để dành mỗi tháng
- **Thống kê**: tổng thu/chi/số dư/tiết kiệm, biểu đồ tròn theo danh mục, cột thu-chi, xu hướng 6 tháng, lọc tháng này/trước/3/6 tháng/năm nay/tùy chọn
- Sao lưu/khôi phục JSON (phiên bản 2, vẫn nhập được bản 1), xuất CSV UTF-8, giao diện sáng/tối/hệ thống

## Hạn chế đã biết
- Sự kiện lặp theo năm chỉ được đặt lại thông báo mỗi lần mở app (không có lặp năm gốc của hệ thống).
- Ngân sách chỉ đặt cho tháng hiện tại; danh mục là chữ tự do (chưa có bảng danh mục riêng).
- Tìm kiếm chỉ áp dụng cho giao dịch.

## Build bằng GitHub Actions
1. Đẩy toàn bộ thư mục này lên một repo GitHub.
2. Tab **Actions** → workflow **Build APK** (tự chạy khi push, hoặc bấm *Run workflow*).
3. Khi xong, mở lần chạy → mục **Artifacts** → tải `LifeSync-release-apk` (chứa `app-release.apk`).

Workflow tự chạy `flutter create` để sinh thư mục `android/`, rồi `tool/patch_android.py` thêm quyền thông báo, receiver khởi động lại máy và core library desugaring.

## Build trên máy
```
flutter create --platform=android --org com.lifesync --project-name lifesync .
python3 tool/patch_android.py
flutter pub get && flutter test && flutter build apk --release
```

## Quyền thông báo
Android 13+: cho phép thông báo khi được hỏi. Nếu chưa cấp quyền báo thức chính xác, app dùng báo thức không chính xác (có thể trễ vài phút). Mở Cài đặt → Ứng dụng → LifeSync → Báo thức & lời nhắc để bật.

## Lưu ý
Múi giờ thông báo cố định Asia/Ho_Chi_Minh. APK release ký bằng khóa debug (đủ để cài thử).

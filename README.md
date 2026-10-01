# LifeSync – Lịch, nhắc nhở & quản lý tài chính (offline)

Ứng dụng Flutter/Android, dữ liệu lưu cục bộ bằng SQLite, không cần tài khoản hay Internet.

## Tính năng đã có
- Lịch tháng, nút Hôm nay, nhảy tới ngày, chấm đánh dấu ngày có sự kiện
- Sự kiện: tiêu đề, chi tiết, giờ, nhắc trước (đúng giờ … 1 ngày), lặp ngày/tuần/tháng (lặp thật), thông báo có âm thanh + rung
- Thu/chi, danh mục tự nhập, tiền lưu số nguyên VND, định dạng `50,000 ₫`
- Nhập nhanh tiếng Việt (`Chi 50k ăn sáng`, `Thu 8tr lương`) – luôn có màn hình xác nhận
- Thống kê: biểu đồ tròn theo danh mục, cột thu/chi, lọc theo thời gian
- Sao lưu/khôi phục JSON (có kiểm tra hợp lệ), xuất CSV UTF-8, giao diện sáng/tối/hệ thống

## Chưa có (chưa triển khai)
Lịch tuần/ngày, lịch âm, ngân sách tháng + cảnh báo, hóa đơn định kỳ, mục tiêu tiết kiệm, khoảng ngày tùy chọn, lặp theo năm.

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

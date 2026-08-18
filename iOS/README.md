# BCEditor for iOS

Ứng dụng SwiftUI native. Toàn bộ package `src/bcsfe` và thư mục `files` của bản gốc được đóng gói vào app; tab **CLI** chạy engine Python nguyên bản trong sandbox iOS và thay `input()` bằng ô nhập SwiftUI. Vì vậy các menu/edit handler của CLI vẫn giữ nguyên hành vi và dữ liệu save, trong khi các chức năng ADB/root không áp dụng trên iOS.

## Build IPA trên GitHub Actions

Workflow `.github/workflows/build-ios-ipa.yml` tải Python iOS framework, đóng gói dependencies + engine, rồi tạo artifact IPA **unsigned**; không cần GitHub Secrets. IPA unsigned không thể cài trực tiếp lên thiết bị iOS cho đến khi bạn ký nó bằng certificate/provisioning profile của mình.

Chạy workflow bằng **Actions → Build iOS IPA → Run workflow**, rồi tải artifact `BCEditor-IPA`.

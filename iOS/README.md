# BCEditor for iOS

Ứng dụng SwiftUI native. Toàn bộ package `src/bcsfe` và thư mục `files` của bản gốc được đóng gói vào app. Các thao tác chỉnh sửa được gọi qua lớp API không tương tác từ các form trong tab Tools; các chức năng ADB/root không áp dụng trên iOS.

## Build IPA trên GitHub Actions

Workflow `.github/workflows/build-ios-ipa.yml` tải Python iOS framework, đóng gói dependencies + engine, rồi tạo artifact IPA **unsigned**; không cần GitHub Secrets. IPA unsigned không thể cài trực tiếp lên thiết bị iOS cho đến khi bạn ký nó bằng certificate/provisioning profile của mình.

Chạy workflow bằng **Actions → Build iOS IPA → Run workflow**, rồi tải artifact `BCEditor-IPA`.

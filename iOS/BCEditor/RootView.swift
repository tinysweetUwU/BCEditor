import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @EnvironmentObject private var store: SaveStore
    @State private var importing = false

    var body: some View {
        GeometryReader { proxy in
            TabView {
                HomeView(openImporter: { importing = true })
                    .tabItem { Label("Home", systemImage: "house.fill") }
                ToolsView()
                    .tabItem { Label("Tools", systemImage: "wrench.and.screwdriver.fill") }
                SaveView(openImporter: { importing = true })
                    .tabItem { Label("Save", systemImage: "externaldrive.fill") }
                CLITerminalView()
                    .tabItem { Label("CLI", systemImage: "terminal.fill") }
                SettingsView()
                    .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .tint(.orange)
        // SAVE_DATA has no extension, so .data can be filtered out by Files on iOS.
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
            if case let .success(urls) = result, let url = urls.first { store.importSave(from: url) }
        }
        .alert("BCEditor", isPresented: Binding(
            get: { store.message != nil },
            set: { if !$0 { store.message = nil } }
        )) {
            Button("OK", role: .cancel) { store.message = nil }
        } message: {
            Text(store.message ?? "")
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: SaveStore
    let openImporter: () -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let save = store.summary {
                        SaveCard(save: save)
                    } else {
                        ContentUnavailableView("Chưa có save", systemImage: "tray.and.arrow.down", description: Text("Mở SAVE_DATA để bắt đầu chỉnh sửa."))
                    }
                    Text("Mỗi lần mở hoặc sửa, ứng dụng tự tạo bản sao lưu trong Files › Trên iPhone của tôi › BCEditor › Backups.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }.navigationTitle("Home")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct SaveCard: View {
    let save: SaveSummary
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Save đang mở", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
            HStack { stat("Phiên bản", save.versionText); Spacer(); stat("Khu vực", save.region.rawValue.uppercased()) }
            Divider(); stat("Cat Food", save.catFood.formatted())
        }.padding(18).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    private func stat(_ title: String, _ value: String) -> some View { VStack(alignment: .leading) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title3.weight(.semibold)) } }
}

struct SaveView: View {
    @EnvironmentObject private var store: SaveStore
    let openImporter: () -> Void
    @State private var exporting = false
    @State private var exportURL: URL?
    var body: some View {
        NavigationStack {
            List {
                Section("File hiện tại") { LabeledContent("Tên file", value: store.fileName); if let s = store.summary { LabeledContent("Kiểm tra", value: "Checksum hợp lệ · \(s.region.rawValue.uppercased())") } }
                Section("Quản lý") {
                    Button("Nhập SAVE_DATA", systemImage: "square.and.arrow.down", action: openImporter)
                    Button("Xuất SAVE_DATA", systemImage: "square.and.arrow.up") { exportURL = store.exportSave(); exporting = exportURL != nil }.disabled(!store.hasSave)
                }
                Section("Lưu ý") { Text("Chỉ nhập file save của chính bạn. Việc sử dụng save đã chỉnh sửa có thể vi phạm điều khoản của trò chơi.").font(.footnote) }
            }.navigationTitle("Save")
        }
        .sheet(isPresented: $exporting) { if let exportURL { ShareSheet(items: [exportURL]) } }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

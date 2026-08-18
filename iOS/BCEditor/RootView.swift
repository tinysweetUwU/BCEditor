import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct RootView: View {
    @EnvironmentObject private var store: SaveStore
    @State private var importing = false

    var body: some View {
        TabView {
            HomeView().tabItem { Label("Home", systemImage: "house.fill") }
            ToolsView().tabItem { Label("Tools", systemImage: "wrench.and.screwdriver.fill") }
            SaveView(openImporter: { importing = true }).tabItem { Label("Save", systemImage: "externaldrive.fill") }
            SettingsView().tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
        }
        .tint(.orange)
        .task { store.prepareFilesDirectories(); store.importPendingSave() }
        .sheet(isPresented: $importing) {
            SaveDocumentPicker(
                onSelection: { result in
                    importing = false
                    if case let .success(urls) = result, let url = urls.first { store.importSave(from: url) }
                },
                onCancel: { importing = false }
            )
            .ignoresSafeArea()
        }
        .alert("BCEditor", isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
            Button("OK", role: .cancel) { store.message = nil }
        } message: { Text(store.message ?? "") }
    }
}

struct SaveDocumentPicker: UIViewControllerRepresentable {
    let onSelection: (Result<[URL], Error>) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onSelection: onSelection, onCancel: onCancel) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSelection: (Result<[URL], Error>) -> Void
        let onCancel: () -> Void
        init(onSelection: @escaping (Result<[URL], Error>) -> Void, onCancel: @escaping () -> Void) {
            self.onSelection = onSelection
            self.onCancel = onCancel
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { onSelection(.success(urls)) }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { onCancel() }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: SaveStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let save = store.summary {
                        SaveCard(save: save)
                    } else {
                        ContentUnavailableView("Chưa có save", systemImage: "tray.and.arrow.down", description: Text("Vào tab Save để nhập SAVE_DATA."))
                    }
                    Text("Bản sao lưu được lưu trong Files → Trên iPhone của tôi → BCEditor → Backups.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }.navigationTitle("Home")
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
    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title3.weight(.semibold)) }
    }
}

struct SaveView: View {
    @EnvironmentObject private var store: SaveStore
    let openImporter: () -> Void
    @State private var exporting = false
    @State private var exportURL: URL?
    var body: some View {
        NavigationStack {
            List {
                Section("Trên iPhone của tôi") {
                    Label("BCEditor / Import", systemImage: "folder.fill")
                    Text("Chép SAVE_DATA vào thư mục này trong Files; app sẽ tự nạp khi mở lại.").font(.footnote).foregroundStyle(.secondary)
                    Button("Quét lại thư mục Import", systemImage: "arrow.clockwise") { store.importPendingSave() }
                }
                Section("File hiện tại") {
                    LabeledContent("Tên file", value: store.fileName)
                    if let summary = store.summary { LabeledContent("Khu vực", value: summary.region.rawValue.uppercased()) }
                }
                Section("Quản lý") {
                    Button("Nhập SAVE_DATA", systemImage: "square.and.arrow.down", action: openImporter)
                    Button("Xuất SAVE_DATA", systemImage: "square.and.arrow.up") { exportURL = store.exportSave(); exporting = exportURL != nil }.disabled(!store.hasSave)
                }
            }.navigationTitle("Save")
        }.sheet(isPresented: $exporting) { if let exportURL { ShareSheet(items: [exportURL]) } }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

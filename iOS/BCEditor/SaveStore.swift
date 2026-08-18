import Foundation
import CryptoKit
import SwiftUI

enum SaveRegion: String, CaseIterable, Identifiable {
    case en, jp, kr, tw
    var id: String { rawValue }
    var patchingCode: String { self == .jp ? "" : rawValue }
}

struct SaveSummary: Equatable {
    let region: SaveRegion
    let gameVersion: Int
    let catFood: Int
    var versionText: String {
        let text = String(format: "%06d", gameVersion)
        return stride(from: 0, to: 6, by: 2).map { String(Int(text[text.index(text.startIndex, offsetBy: $0)..<text.index(text.startIndex, offsetBy: $0 + 2)]) ?? 0) }.joined(separator: ".")
    }
}

@MainActor
final class SaveStore: ObservableObject {
    @Published private(set) var summary: SaveSummary?
    @Published private(set) var basicValues: [String: Int] = [:]
    @Published private(set) var fileName = "Chưa chọn save"
    @Published var message: String?
    @Published var selectedRegion: SaveRegion = .en
    private var data = Data()
    private var sourceURL: URL?

    init() {
        prepareFilesDirectories()
    }

    var hasSave: Bool { summary != nil }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func prepareFilesDirectories() {
        for folder in ["Import", "Exports", "Backups"] {
            try? FileManager.default.createDirectory(
                at: documentsDirectory.appendingPathComponent(folder, isDirectory: true),
                withIntermediateDirectories: true
            )
        }
    }

    func importPendingSave() {
        prepareFilesDirectories()
        let folder = documentsDirectory.appendingPathComponent("Import", isDirectory: true)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        ), let file = files.first(where: { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true }) else { return }
        importSave(from: file)
    }

    func importSave(from url: URL) {
        do {
            let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey])
            guard values.isRegularFile == true, values.isDirectory != true, values.isSymbolicLink != true else { throw SaveError.invalid }
            // Read the provider URL while its security scope is active, then work
            // only with an app-owned copy. This also handles iCloud/Files URLs.
            let imported = try Data(contentsOf: url, options: .mappedIfSafe)
            let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("BCEditor-import-\(UUID().uuidString)")
            try? FileManager.default.removeItem(at: localURL)
            try imported.write(to: localURL, options: .atomic)
            guard let result = Self.inspect(imported) else { throw SaveError.invalid }
            data = imported; summary = result; selectedRegion = result.region; sourceURL = url; fileName = url.lastPathComponent
            loadBasicValues(from: localURL)
            backup()
            message = "Đã mở save v\(result.versionText) (\(result.region.rawValue.uppercased()))."
        } catch { message = "Không thể mở file này. Hãy chọn SAVE_DATA nguyên gốc." }
    }

    func updateCatFood(_ amount: Int) {
        guard var summary, let offset = Self.catFoodOffset(for: summary) else { return }
        var littleEndian = Int32(clamping: amount).littleEndian
        withUnsafeBytes(of: &littleEndian) { data.replaceSubrange(offset..<(offset + 4), with: $0) }
        guard let region = SaveRegion(rawValue: summary.region.rawValue) else { return }
        reseal(region: region)
        summary = SaveSummary(region: region, gameVersion: summary.gameVersion, catFood: amount)
        self.summary = summary
        basicValues["catfood"] = amount
        backup()
        message = "Đã cập nhật Cat Food và kiểm tra checksum."
    }

    private func loadBasicValues(from url: URL) {
        let fields = ["catfood", "xp", "normal_tickets", "rare_tickets", "platinum_tickets", "legend_tickets", "hundred_million_ticket", "platinum_shards", "np", "leadership", "rare_seed", "normal_seed", "event_seed"]
        let path = url.path
        DispatchQueue.global(qos: .userInitiated).async {
            var values: [String: Int] = [:]
            for field in fields { values[field] = Int(BCEPythonReadValue(path, field)) }
            DispatchQueue.main.async { self.basicValues = values }
        }
    }

    // Native Tools calls this method directly; no interactive input is used.
    func updateBasicItem(_ field: String, value: Int) {
        guard let url = exportSave() else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = BCEPythonWriteValue(url.path, field, value)
            DispatchQueue.main.async {
                if ok { self.importSave(from: url) }
                self.message = ok ? "Đã cập nhật \(field)." : "Không thể cập nhật \(field)."
            }
        }
    }

    func applyNativeAction(_ action: String, value: Int = 0) {
        guard let url = exportSave() else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = BCEPythonApplyAction(url.path, action, value)
            DispatchQueue.main.async {
                if ok { self.importSave(from: url) }
                self.message = ok ? "Đã áp dụng thay đổi." : "Không thể áp dụng thay đổi cho save này."
            }
        }
    }

    func exportSave() -> URL? {
        guard hasSave else { return nil }
        let url = documentsDirectory.appendingPathComponent("Exports", isDirectory: true).appendingPathComponent("SAVE_DATA")
        do { prepareFilesDirectories(); try data.write(to: url, options: .atomic); return url } catch { message = "Không thể tạo file xuất."; return nil }
    }

    func importPythonSaveIfPresent() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("saves", isDirectory: true).appendingPathComponent("SAVE_DATA")
        if FileManager.default.fileExists(atPath: support.path) { importSave(from: support) }
    }

    private func backup() {
        guard !data.isEmpty else { return }
        let directory = documentsDirectory.appendingPathComponent("Backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        try? data.write(to: directory.appendingPathComponent("SAVE_DATA-\(formatter.string(from: .now).replacingOccurrences(of: ":", with: "-"))"), options: .atomic)
    }

    private func reseal(region: SaveRegion) {
        guard data.count >= 32 else { return }
        let payload = Data(data.dropLast(32))
        let digest = Insecure.MD5.hash(data: Data("battlecats\(region.patchingCode)".utf8) + payload)
        data.replaceSubrange((data.count - 32)..<data.count, with: Data(digest.map { String(format: "%02x", $0) }.joined().utf8))
    }

    private static func inspect(_ data: Data) -> SaveSummary? {
        guard data.count >= 40 else { return nil }
        for region in SaveRegion.allCases where validHash(data, region: region) {
            let version = readInt(data, at: 0)
            let offset = version >= 10 || region != .jp ? 7 : 6
            return SaveSummary(region: region, gameVersion: version, catFood: readInt(data, at: offset))
        }
        return nil
    }

    private static func validHash(_ data: Data, region: SaveRegion) -> Bool {
        guard let stored = String(data: data.suffix(32), encoding: .utf8) else { return false }
        let digest = Insecure.MD5.hash(data: Data("battlecats\(region.patchingCode)".utf8) + Data(data.dropLast(32)))
        let expected = digest.map { String(format: "%02x", $0) }.joined()
        return stored.lowercased() == expected
    }

    private static func catFoodOffset(for summary: SaveSummary) -> Int? { summary.gameVersion >= 10 || summary.region != .jp ? 7 : 6 }
    private static func readInt(_ data: Data, at offset: Int) -> Int {
        guard data.count >= offset + 4 else { return 0 }
        return data[offset..<(offset + 4)].withUnsafeBytes { Int(Int32(littleEndian: $0.loadUnaligned(as: Int32.self))) }
    }
    private enum SaveError: Error { case invalid }
}

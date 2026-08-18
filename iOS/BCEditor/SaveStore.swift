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
            // Files providers may return a security-scoped, non-local URL. Copy it
            // into the app's temporary container before parsing.
            let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("BCEditor-import-\(UUID().uuidString)")
            try? FileManager.default.removeItem(at: localURL)
            try FileManager.default.copyItem(at: url, to: localURL)
            let imported = try Data(contentsOf: localURL, options: .mappedIfSafe)
            guard let result = Self.inspect(imported) else { throw SaveError.invalid }
            data = imported; summary = result; selectedRegion = result.region; sourceURL = url; fileName = url.lastPathComponent
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
        self.summary = summary; backup(); message = "Đã cập nhật Cat Food và kiểm tra lại checksum."
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
        data.replaceSubrange((data.count - 32)..<data.count, with: Data(digest.description.utf8))
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
        return stored.lowercased() == digest.description.lowercased()
    }

    private static func catFoodOffset(for summary: SaveSummary) -> Int? { summary.gameVersion >= 10 || summary.region != .jp ? 7 : 6 }
    private static func readInt(_ data: Data, at offset: Int) -> Int {
        guard data.count >= offset + 4 else { return 0 }
        return data[offset..<(offset + 4)].withUnsafeBytes { Int(Int32(littleEndian: $0.loadUnaligned(as: Int32.self))) }
    }
    private enum SaveError: Error { case invalid }
}

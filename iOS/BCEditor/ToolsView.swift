import SwiftUI

struct EditorTool: Identifiable, Hashable { let id = UUID(); let title: String; let icon: String; let color: Color; let features: [String] }

struct ToolsView: View {
    private let tools = [
        EditorTool(title: "Items", icon: "shippingbox.fill", color: .orange, features: ["Cat Food", "XP", "Normal / Rare / Platinum Tickets", "NP, Leadership, Battle Items", "Catseyes, Catfruit, Catamins, Orbs"]),
        EditorTool(title: "Cats & Skills", icon: "pawprint.fill", color: .pink, features: ["Mở khóa / xóa Cats", "Level, Plus Level, Forms", "Talents & Cat Guide", "Special Skills & Cat Storage"]),
        EditorTool(title: "Levels", icon: "map.fill", color: .indigo, features: ["Story, SOL, Event & Collab", "Towers, Gauntlets, Zero Legends", "Aku Realm, Enigma, Outbreaks", "Treasures, Dojo & Challenge"]),
        EditorTool(title: "Gamatoto", icon: "hammer.fill", color: .teal, features: ["Engineers & Base Materials", "Gamatoto XP / Helpers", "Ototo Cat Cannon", "Cat Shrine"]),
        EditorTool(title: "Account", icon: "person.crop.circle.fill", color: .blue, features: ["Inquiry Code", "Password Refresh Token", "Managed Items", "Region & Game Version"]),
        EditorTool(title: "Gatya & Other", icon: "sparkles", color: .purple, features: ["Gatya Seeds", "Missions & Medals", "Gold Pass & Playtime", "Fixes / crash recovery"])
    ]
    var body: some View {
        NavigationStack { ScrollView { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) { ForEach(tools) { tool in NavigationLink(value: tool) { ToolTile(tool: tool) } } }.padding() }
            .navigationTitle("Tools").navigationDestination(for: EditorTool.self) { ToolDetail(tool: $0) }
        }
    }
}

struct ToolTile: View { let tool: EditorTool; var body: some View { VStack(alignment: .leading, spacing: 12) { Image(systemName: tool.icon).font(.title).foregroundStyle(.white).frame(width: 44, height: 44).background(tool.color.gradient, in: RoundedRectangle(cornerRadius: 13)); Text(tool.title).font(.headline).foregroundStyle(.primary); Text("\(tool.features.count) nhóm") .font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, minHeight: 138, alignment: .leading).padding().background(.background, in: RoundedRectangle(cornerRadius: 20)).shadow(color: .black.opacity(0.08), radius: 8, y: 3) } }

struct ToolDetail: View {
    @EnvironmentObject private var store: SaveStore
    let tool: EditorTool
    @State private var catFood = ""
    var body: some View {
        Form {
            if tool.title == "Items" { Section("Chỉnh sửa trực tiếp") { TextField("Cat Food", text: $catFood).keyboardType(.numberPad); Button("Áp dụng Cat Food") { if let value = Int(catFood) { store.updateCatFood(value) } }.disabled(!store.hasSave) } }
            Section("Chức năng") { ForEach(tool.features, id: \.self) { Label($0, systemImage: "checkmark.circle") } }
            Section("Tình trạng") { Text(store.hasSave ? "Đã có save để chỉnh sửa." : "Hãy mở SAVE_DATA từ tab Save trước.").foregroundStyle(store.hasSave ? .green : .secondary) }
        }.navigationTitle(tool.title).onAppear { catFood = store.summary.map { String($0.catFood) } ?? "" }
    }
}

struct SettingsView: View { var body: some View { NavigationStack { List { Section("Ứng dụng") { LabeledContent("Phiên bản", value: "1.0.0"); Label("Giao diện iOS native", systemImage: "iphone") } Section("An toàn") { Text("BCEditor luôn kiểm tra checksum trước khi nhận save và tạo bản sao trước khi thay đổi.") } }.navigationTitle("Cài đặt") } } }

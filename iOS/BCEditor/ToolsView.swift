import SwiftUI

struct GitHubProfile: Decodable { let login: String; let name: String?; let avatarURL: URL; let htmlURL: URL
    enum CodingKeys: String, CodingKey { case login, name; case avatarURL = "avatar_url"; case htmlURL = "html_url" }
}
@MainActor final class GitHubAuthor: ObservableObject {
    @Published var profile = GitHubProfile(login: "tinysweetUwU", name: "tinysweet", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/110331292?v=4")!, htmlURL: URL(string: "https://github.com/tinysweetUwU")!)
    init() { Task { if let url = URL(string: "https://api.github.com/users/tinysweetUwU") { var req = URLRequest(url: url); req.setValue("BCEditor", forHTTPHeaderField: "User-Agent"); if let (data, _) = try? await URLSession.shared.data(for: req), let profile = try? JSONDecoder().decode(GitHubProfile.self, from: data) { self.profile = profile } } } }
}

struct EditorTool: Identifiable, Hashable { let id = UUID(); let title: String; let icon: String; let color: Color; let features: [String] }

struct ToolsView: View {
    private let tools = [
        EditorTool(title: "Items", icon: "shippingbox.fill", color: .orange, features: ["Cat Food", "XP", "Tickets", "NP / Leadership", "Catfruit / Catseyes / Catamins", "Battle Items"]),
        EditorTool(title: "Cats & Skills", icon: "pawprint.fill", color: .pink, features: ["Cat ID / level", "Unlock and max forms", "Talents", "Cat Storage"]),
        EditorTool(title: "Levels", icon: "map.fill", color: .indigo, features: ["Aku Realm", "All available stages"]),
        EditorTool(title: "Gamatoto", icon: "hammer.fill", color: .teal, features: ["XP / expedition", "Ototo cannons"]),
        EditorTool(title: "Account", icon: "person.crop.circle.fill", color: .blue, features: ["Equipment menu", "Gold Pass reset"]),
        EditorTool(title: "Gatya & Other", icon: "sparkles", color: .purple, features: ["Gatya seeds", "Missions", "Medals"]),
        EditorTool(title: "Fixes", icon: "wrench.and.screwdriver.fill", color: .red, features: ["Gamatoto", "Ototo", "Time errors"])
    ]
    var body: some View { NavigationStack { ScrollView { LazyVStack(spacing: 14) { ForEach(tools) { tool in NavigationLink { ToolDetail(tool: tool) } label: { ToolTile(tool: tool) } } }.padding() }.navigationTitle("Tools") } }
}
struct ToolTile: View { let tool: EditorTool; var body: some View { HStack(spacing: 14) { Image(systemName: tool.icon).font(.title2).foregroundStyle(.white).frame(width: 48, height: 48).background(tool.color.gradient, in: RoundedRectangle(cornerRadius: 13)); VStack(alignment: .leading) { Text(tool.title).font(.headline); Text("(tool.features.count) editors").font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary) }.padding().frame(maxWidth: .infinity).background(.background, in: RoundedRectangle(cornerRadius: 18)).shadow(color: .black.opacity(0.08), radius: 8, y: 3) } }

struct ToolDetail: View {
    @EnvironmentObject private var store: SaveStore; let tool: EditorTool
    @State private var values: [String: String] = ["catfood":"", "xp":"", "normal_tickets":"", "rare_tickets":"", "platinum_tickets":"", "platinum_shards":"", "np":"", "leadership":"", "rare_seed":"", "normal_seed":"", "event_seed":""]
    @State private var catID = "0"; @State private var catLevel = "1"
    var body: some View { Form {
        if tool.title == "Items" { Section("Direct edit") { field("Cat Food", "catfood"); field("XP", "xp"); field("Normal Tickets", "normal_tickets"); field("Rare Tickets", "rare_tickets"); field("Platinum Tickets", "platinum_tickets"); field("Platinum Shards", "platinum_shards"); field("NP", "np"); field("Leadership", "leadership"); action("Max basic items", "max_items", "arrow.up.to.line"); action("Max resources", "max_resources", "leaf.fill"); action("Max battle items", "max_battle_items", "shield.fill") } }
        if tool.title == "Cats & Skills" { Section("Direct edit") { TextField("Cat ID", text: $catID).keyboardType(.numberPad); TextField("Base level", text: $catLevel).keyboardType(.numberPad); Button("Apply cat level", systemImage: "pencil") { if let id = Int(catID), let level = Int(catLevel) { store.applyNativeAction("set_cat_level", value: (id << 16) | level) } }.disabled(!store.hasSave); action("Unlock all cats", "unlock_all_cats", "lock.open.fill"); action("Max cats and forms", "max_cats", "star.fill"); action("Max talents", "max_talents", "sparkles"); action("Fill Cat Storage", "fill_cat_storage", "tray.full.fill"); action("Clear Cat Storage", "clear_cat_storage", "trash") } }
        if tool.title == "Levels" { Section("Direct edit") { action("Unlock Aku Realm", "unlock_aku_realm", "lock.open.fill"); action("Clear available stages", "clear_all_maps", "map.fill") } }
        if tool.title == "Gamatoto" { Section("Direct edit") { action("Max Gamatoto XP", "max_gamatoto", "hammer.fill"); action("Max Ototo cannons", "max_ototo_cannons", "bolt.fill") } }
        if tool.title == "Account" { Section("Direct edit") { action("Unlock equipment menu", "unlock_equip_menu", "lock.open.fill"); action("Reset Gold Pass", "reset_officer_pass", "arrow.counterclockwise") } }
        if tool.title == "Gatya & Other" { Section("Direct edit") { field("Rare Gatya Seed", "rare_seed"); field("Normal Gatya Seed", "normal_seed"); field("Event Gatya Seed", "event_seed"); action("Complete missions", "complete_missions", "checkmark.seal.fill"); action("Unlock medals", "unlock_medals", "rosette") } }
        if tool.title == "Fixes" { Section("Direct fixes") { action("Fix Gamatoto", "fix_gamatoto_crash", "wrench.and.screwdriver"); action("Fix Ototo", "fix_ototo_crash", "hammer.fill"); action("Fix time errors", "fix_time_errors", "clock.arrow.2.circlepath") } }
        Section("Features") { ForEach(tool.features, id: \.self) { Label($0, systemImage: "checkmark.circle") } }
    }.navigationTitle(tool.title).onAppear { refresh() }.onChange(of: store.basicValues) { _, _ in refresh() } }
    @ViewBuilder private func field(_ title: String, _ key: String) -> some View { HStack { TextField(title, text: Binding(get: { values[key] ?? "" }, set: { values[key] = $0 })).keyboardType(.numberPad); Button("Apply") { if let value = Int(values[key] ?? "") { store.updateBasicItem(key, value: value) } }.disabled(!store.hasSave || Int(values[key] ?? "") == nil) } }
    private func action(_ title: String, _ key: String, _ icon: String) -> some View { Button(title, systemImage: icon) { store.applyNativeAction(key) }.disabled(!store.hasSave) }
    private func refresh() { for key in values.keys { if let value = store.basicValues[key] { values[key] = String(value) } } }
}

struct SettingsView: View { @StateObject private var author = GitHubAuthor(); var body: some View { NavigationStack { List { Section("Application") { LabeledContent("Version", value: "1.0.1") }; Section("Author") { HStack { AsyncImage(url: author.profile.avatarURL) { phase in if let image = phase.image { image.resizable().scaledToFill() } else { Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().foregroundStyle(.secondary) } }.frame(width: 56, height: 56).clipShape(Circle()); VStack(alignment: .leading) { Text(author.profile.name ?? author.profile.login).font(.headline); Text("@\(author.profile.login)").font(.caption).foregroundStyle(.secondary) }; Spacer() }; Link(destination: author.profile.htmlURL) { Label("Open GitHub profile", systemImage: "link") } }; Section("Safety") { Text("A backup is created before every native edit.") } }.navigationTitle("Settings") } } }

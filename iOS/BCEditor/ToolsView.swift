import SwiftUI

struct GitHubProfile: Decodable {
    let login: String
    let name: String?
    let avatarURL: URL
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case login, name
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
    }
}

@MainActor
final class GitHubAuthor: ObservableObject {
    @Published var profile = GitHubProfile(
        login: "tinysweetUwU",
        name: "tinysweet",
        avatarURL: URL(string: "https://avatars.githubusercontent.com/u/110331292?v=4")!,
        htmlURL: URL(string: "https://github.com/tinysweetUwU")!
    )

    init() {
        Task {
            guard let url = URL(string: "https://api.github.com/users/tinysweetUwU") else { return }
            var request = URLRequest(url: url)
            request.setValue("BCEditor", forHTTPHeaderField: "User-Agent")
            if let (data, _) = try? await URLSession.shared.data(for: request),
               let fetched = try? JSONDecoder().decode(GitHubProfile.self, from: data) {
                profile = fetched
            }
        }
    }
}

struct EditorTool: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let features: [String]
    let menuIndex: Int
}

struct ToolsView: View {
    private let tools: [EditorTool] = [
        EditorTool(title: "Items", icon: "shippingbox.fill", color: .orange, features: ["Cat Food", "XP", "Normal / Rare / Platinum Tickets", "NP, Leadership, Battle Items", "Catseyes, Catfruit, Catamins, Orbs"], menuIndex: 2),
        EditorTool(title: "Cats & Skills", icon: "pawprint.fill", color: .pink, features: ["Unlock / remove Cats", "Level, Plus Level, Forms", "Talents & Cat Guide", "Special Skills & Cat Storage"], menuIndex: 3),
        EditorTool(title: "Levels", icon: "map.fill", color: .indigo, features: ["Story, SOL, Event & Collab", "Towers, Gauntlets, Zero Legends", "Aku Realm, Enigma, Outbreaks", "Treasures, Dojo & Challenge"], menuIndex: 4),
        EditorTool(title: "Gamatoto", icon: "hammer.fill", color: .teal, features: ["Engineers & Base Materials", "Gamatoto XP / Helpers", "Ototo Cat Cannon", "Cat Shrine"], menuIndex: 5),
        EditorTool(title: "Account", icon: "person.crop.circle.fill", color: .blue, features: ["Inquiry Code", "Password Refresh Token", "Managed Items", "Region & Game Version"], menuIndex: 6),
        EditorTool(title: "Gatya & Other", icon: "sparkles", color: .purple, features: ["Gatya Seeds", "Missions & Medals", "Gold Pass & Playtime", "Fixes / crash recovery"], menuIndex: 7)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(tools) { tool in
                        NavigationLink {
                            ToolDetail(tool: tool)
                        } label: {
                            ToolTile(tool: tool)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Tools")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ToolTile: View {
    let tool: EditorTool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: tool.icon)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(tool.color.gradient, in: RoundedRectangle(cornerRadius: 13))
            Text(tool.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text("\(tool.features.count) groups")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }
}

struct ToolDetail: View {
    @EnvironmentObject private var store: SaveStore
    let tool: EditorTool
    @State private var catFood = ""
    @State private var xp = ""
    @State private var normalTickets = ""
    @State private var rareTickets = ""
    @State private var platinumTickets = ""
    @State private var platinumShards = ""
    @State private var np = ""
    @State private var leadership = ""
    @State private var showingEditor = false

    var body: some View {
        Form {
            if tool.title == "Items" {
                Section("Direct edit") {
                    directField("Cat Food", text: $catFood, field: "catfood")
                    directField("XP", text: $xp, field: "xp")
                    directField("Normal Tickets", text: $normalTickets, field: "normal_tickets")
                    directField("Rare Tickets", text: $rareTickets, field: "rare_tickets")
                    directField("Platinum Tickets", text: $platinumTickets, field: "platinum_tickets")
                    directField("Platinum Shards", text: $platinumShards, field: "platinum_shards")
                    directField("NP", text: $np, field: "np")
                    directField("Leadership", text: $leadership, field: "leadership")
                    Button("Max all basic items", systemImage: "arrow.up.to.line") {
                        store.applyNativeAction("max_items")
                    }
                    .disabled(!store.hasSave)
                }
            } else if tool.title == "Cats & Skills" {
                Section("Direct edit") {
                    Button("Unlock all cats", systemImage: "lock.open.fill") {
                        store.applyNativeAction("unlock_all_cats")
                    }
                    .disabled(!store.hasSave)
                    Button("Unlock, max level and forms", systemImage: "star.fill") {
                        store.applyNativeAction("max_cats")
                    }
                    .disabled(!store.hasSave)
                }
            } else if tool.title == "Levels" {
                Section("Direct edit") {
                    Button("Unlock Aku Realm", systemImage: "lock.open.fill") {
                        store.applyNativeAction("unlock_aku_realm")
                    }
                    .disabled(!store.hasSave)
                }
            } else {
                Section("Editor") {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("Open \(tool.title) editor", systemImage: "pencil.and.outline")
                    }
                    .disabled(!store.hasSave)
                    Text("Chọn một mục để chỉnh sửa trực tiếp trên save đang mở.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("Features") {
                ForEach(tool.features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.circle")
                }
            }

            Section("Status") {
                Text(store.hasSave ? "A save is ready to edit." : "Open SAVE_DATA from the Save tab first.")
                    .foregroundStyle(store.hasSave ? .green : .secondary)
            }
        }
        .navigationTitle(tool.title)
        .onAppear {
            catFood = store.summary.map { String($0.catFood) } ?? ""
        }
        .alert("Editor đang được mở rộng", isPresented: $showingEditor) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Mục Cat Food đã chỉnh sửa trực tiếp. Các nhóm còn lại sẽ dùng cùng bộ máy chỉnh sửa trong bản cập nhật tiếp theo.")
        }
    }

    @ViewBuilder
    private func directField(_ title: String, text: Binding<String>, field: String) -> some View {
        HStack {
            TextField(title, text: text).keyboardType(.numberPad)
            Button("Apply") {
                if let value = Int(text.wrappedValue) { store.updateBasicItem(field, value: value) }
            }
            .disabled(!store.hasSave || Int(text.wrappedValue) == nil)
        }
    }
}

struct SettingsView: View {
    @StateObject private var author = GitHubAuthor()

    var body: some View {
        NavigationStack {
            List {
                Section("Application") {
                    LabeledContent("Version", value: "1.0.0")
                }
                Section("Author") {
                    HStack(spacing: 14) {
                        AsyncImage(url: author.profile.avatarURL) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable().scaledToFit().foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(author.profile.name ?? author.profile.login).font(.headline)
                            Text("@\(author.profile.login)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    Link(destination: author.profile.htmlURL) {
                        Label("Open GitHub repository", systemImage: "link")
                    }
                }
                Section("Safety") {
                    Text("BCEditor checks the save checksum and creates a backup before changes.")
                }
            }
            .navigationTitle("Settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

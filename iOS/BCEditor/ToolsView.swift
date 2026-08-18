import SwiftUI

struct EditorTool: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let features: [String]
}

struct ToolsView: View {
    private let tools: [EditorTool] = [
        EditorTool(title: "Items", icon: "shippingbox.fill", color: .orange, features: ["Cat Food", "XP", "Normal / Rare / Platinum Tickets", "NP, Leadership, Battle Items", "Catseyes, Catfruit, Catamins, Orbs"]),
        EditorTool(title: "Cats & Skills", icon: "pawprint.fill", color: .pink, features: ["Unlock / remove Cats", "Level, Plus Level, Forms", "Talents & Cat Guide", "Special Skills & Cat Storage"]),
        EditorTool(title: "Levels", icon: "map.fill", color: .indigo, features: ["Story, SOL, Event & Collab", "Towers, Gauntlets, Zero Legends", "Aku Realm, Enigma, Outbreaks", "Treasures, Dojo & Challenge"]),
        EditorTool(title: "Gamatoto", icon: "hammer.fill", color: .teal, features: ["Engineers & Base Materials", "Gamatoto XP / Helpers", "Ototo Cat Cannon", "Cat Shrine"]),
        EditorTool(title: "Account", icon: "person.crop.circle.fill", color: .blue, features: ["Inquiry Code", "Password Refresh Token", "Managed Items", "Region & Game Version"]),
        EditorTool(title: "Gatya & Other", icon: "sparkles", color: .purple, features: ["Gatya Seeds", "Missions & Medals", "Gold Pass & Playtime", "Fixes / crash recovery"])
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(tools) { tool in
                        NavigationLink(value: tool) {
                            ToolTile(tool: tool)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Tools")
            .navigationDestination(for: EditorTool.self) { tool in
                ToolDetail(tool: tool)
            }
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

    var body: some View {
        Form {
            if tool.title == "Items" {
                Section("Direct edit") {
                    TextField("Cat Food", text: $catFood)
                        .keyboardType(.numberPad)
                    Button("Apply Cat Food") {
                        if let value = Int(catFood) {
                            store.updateCatFood(value)
                        }
                    }
                    .disabled(!store.hasSave)
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
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Application") {
                    LabeledContent("Version", value: "1.0.0")
                    Label("Native iOS interface", systemImage: "iphone")
                }
                Section("Safety") {
                    Text("BCEditor checks the save checksum and creates a backup before changes.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

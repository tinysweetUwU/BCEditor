import SwiftUI

@main
struct BCEditorApp: App {
    @StateObject private var store = SaveStore()

    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
        }
    }
}

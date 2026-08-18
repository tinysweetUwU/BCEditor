import SwiftUI

struct CLITerminalView: View {
    @EnvironmentObject private var store: SaveStore
    @State private var output = "BCEditor engine sẵn sàng. Mở save rồi nhấn Bắt đầu để dùng toàn bộ menu CLI.\n"
    @State private var input = ""
    @State private var running = false
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView { Text(output).font(.system(.footnote, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).padding().id("output") }
                        .background(Color.black).foregroundStyle(.green)
                        .onChange(of: output) { _, _ in withAnimation { proxy.scrollTo("output", anchor: .bottom) } }
                }
                HStack {
                    TextField("Nhập lựa chọn CLI…", text: $input).textFieldStyle(.roundedBorder).disabled(!running).onSubmit { submit() }
                    Button(action: submit) { Image(systemName: "arrow.up.circle.fill").font(.title2) }.disabled(!running || input.isEmpty)
                }.padding()
            }
            .navigationTitle("Full CLI engine")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(running ? "Đang chạy" : "Bắt đầu", systemImage: running ? "hourglass" : "play.fill") { start() }.disabled(running || !store.hasSave) } }
        }
        .onDisappear { timer?.invalidate() }
    }

    private func start() {
        guard let url = store.exportSave() else { return }
        output += "\n> Khởi động toàn bộ BCSFE Python…\n"
        BCEPythonStart(url.path); running = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            let chunk = BCEPythonDrainOutput(); if !chunk.isEmpty { output += chunk }
            if !BCEPythonIsRunning() { running = false; timer?.invalidate(); store.importPythonSaveIfPresent(); output += "\n[engine đã dừng]\n" }
        }
    }

    private func submit() { let line = input; input = ""; output += "\n> \(line)\n"; BCEPythonSubmitInput(line) }
}

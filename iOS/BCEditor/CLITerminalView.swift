import SwiftUI

/// Group-scoped editor session used from Tools. It drives the original parser
/// for the selected group while the surrounding UI remains native SwiftUI.
struct FeatureSessionView: View {
    @EnvironmentObject private var store: SaveStore
    let tool: EditorTool
    @State private var output = ""
    @State private var input = ""
    @State private var running = false
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(output.isEmpty ? "Nhấn Bắt đầu để mở nhóm chỉnh sửa (tool.title)." : output)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("output")
                }
                .background(Color(uiColor: .secondarySystemBackground))
                .onChange(of: output) { _, _ in withAnimation { proxy.scrollTo("output", anchor: .bottom) } }
            }
            HStack {
                TextField("Nhập lựa chọn hoặc giá trị…", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!running)
                    .onSubmit(submit)
                Button(action: submit) { Image(systemName: "arrow.up.circle.fill").font(.title2) }
                    .disabled(!running || input.isEmpty)
            }
            .padding()
            Button(running ? "Đang chạy" : "Bắt đầu (tool.title)", systemImage: running ? "hourglass" : "play.fill", action: start)
                .buttonStyle(.borderedProminent)
                .disabled(running || !store.hasSave)
                .padding(.bottom)
        }
        .navigationTitle(tool.title)
        .onDisappear { timer?.invalidate() }
    }

    private func start() {
        guard let url = store.exportSave() else { return }
        output = "Đang mở bộ chỉnh sửa (tool.title)…\n"
        BCEPythonStart(url.path)
        running = true
        // The engine first prints its welcome screen, then waits for the top-level group.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            BCEPythonSubmitInput(String(tool.menuIndex))
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            let chunk = BCEPythonDrainOutput()
            if !chunk.isEmpty { output += chunk }
            if !BCEPythonIsRunning() {
                running = false
                timer?.invalidate()
                store.importPythonSaveIfPresent()
            }
        }
    }

    private func submit() {
        let line = input
        input = ""
        output += "\n> (line)\n"
        BCEPythonSubmitInput(line)
    }
}

struct CLITerminalView: View {
    @EnvironmentObject private var store: SaveStore
    @State private var output = "BCEditor Full Editor sẵn sàng. Nhấn Bắt đầu để mở toàn bộ chức năng chỉnh sửa.\n"
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
                    TextField("Nhập lựa chọn…", text: $input).textFieldStyle(.roundedBorder).disabled(!running).onSubmit { submit() }
                    Button(action: submit) { Image(systemName: "arrow.up.circle.fill").font(.title2) }.disabled(!running || input.isEmpty)
                }.padding()
            }
            .navigationTitle("Full Editor")
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

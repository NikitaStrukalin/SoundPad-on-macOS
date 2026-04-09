//
//  KeybindingView.swift
//  SoundPad
//
//  Created by Никита Струкалин on 09.04.2026.
//

import AppKit
import SwiftUI
import SwiftData

struct KeybindingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    var item: Item
    @State private var key: String = "..."
    @State private var showDuplicateAlert = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            // Монитор событий
            KeyCaptureView(keyString: $key)
                .frame(width: 0, height: 0)

            VStack(spacing: 20) {
                Text("Нажмите на клавишу(-и)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.black)

                Text(key)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding()
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(12)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Button {
                    saveBinding()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Назначить")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
                }
                .buttonStyle(PressablePillStyle())
            }
            .background(Color(.white))
            .padding(40)
        }
        .frame(width: 400, height: 300)
        .alert("Дубликат", isPresented: $showDuplicateAlert) {
            Button("ОК", role: .cancel) {}
        } message: {
            Text("Эта клавиша уже занята другим звуком.")
        }
    }

    private func saveBinding() {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "..." || trimmed.isEmpty { dismiss(); return }
        
        let descriptor = FetchDescriptor<Item>()
        let allItems = (try? modelContext.fetch(descriptor)) ?? []
        
        if allItems.contains(where: { $0.keyBinding == trimmed && $0.id != item.id }) {
            showDuplicateAlert = true
        } else {
            item.keyBinding = trimmed
            dismiss()
        }
    }
}

// РАБОЧИЙ захват клавиш для macOS
private struct KeyCaptureView: NSViewRepresentable {
    @Binding var keyString: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Важно: используем localMonitor, чтобы перехватывать нажатия в активном окне
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mappedKey = KeyCaptureView.format(event: event)
            
            // Обновляем UI в главном потоке
            DispatchQueue.main.async {
                self.keyString = mappedKey
            }
            return nil // nil поглощает нажатие, чтобы система не "пищала"
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func format(event: NSEvent) -> String {
        var parts: [String] = []
        let flags = event.modifierFlags
        
        if flags.contains(.command) { parts.append("⌘") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.control) { parts.append("⌃") }
        
        let specialKeys: [UInt16: String] = [
            53: "ESC", 36: "↩", 48: "TAB", 51: "⌫", 49: "Space",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        
        if let special = specialKeys[event.keyCode] {
            parts.append(special)
        } else if let chars = event.charactersIgnoringModifiers?.uppercased(), !chars.isEmpty {
            parts.append(chars)
        }
        
        let result = parts.joined(separator: "")
        return result.isEmpty ? "..." : result
    }
}

private struct PressablePillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

//
//  ContentView.swift
//  SoundPad
//
//  Created by Никита Струкалин on 09.04.2026.
//

import SwiftUI
import SwiftData
import AVFoundation
import AppKit

// MARK: - Основной Интерфейс
struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Item.name) var sounds: [Item]
    
    @State private var audioManager = AudioManager()
    @State private var isImporting: Bool = false
    @State private var searchText = ""
    @State private var selectedSoundForKeybinding: Item? = nil
    
    // Фильтр для поиска
    var filteredSounds: [Item] {
        searchText.isEmpty ? sounds : sounds.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Soundpad")
                            .font(.system(size: geometry.size.width * 0.05, weight: .black, design: .rounded))
                            .foregroundStyle(Color.black)
                            .padding(.leading)
                            .padding(.top)
                        
                        Button {
                            isImporting = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.blackGlassCircle)
                        .padding(.top)
                    }
                    
                    TextField("Поиск звука...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.black)
                        .tint(.black)
                        .padding(10)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(10)
                        .colorScheme(.light)
                        .padding(.horizontal)
                        .padding(.top, 20)

                    ScrollView(.vertical) {
                        VStack(spacing: 12) {
                            ForEach(filteredSounds) { sound in
                                SoundRowView(sound: sound, audioManager: audioManager, selectedSound: $selectedSoundForKeybinding)
                            }
                        }
                        .padding()
                    }
                    .scrollIndicators(.visible)
                }
            }
        }
        .sheet(item: $selectedSoundForKeybinding) { item in
            KeybindingView(item: item)
        }
        .onAppear {
            audioManager.setupMonitoring(container: modelContext.container)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.mp3, .audio, .mpeg4Audio],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                for url in urls {
                    importFile(from: url, modelContext: modelContext)
                }
            }
        }
    }
}

// MARK: - Строка списка
struct SoundRowView: View {
    let sound: Item
    let audioManager: AudioManager
    @Binding var selectedSound: Item?
    @Environment(\.modelContext) var modelContext

    var body: some View {
        HStack {
            Button {
                audioManager.play(data: sound.audioData, id: sound.id)
            } label: {
                Image(systemName: audioManager.currentlyPlayingID == sound.id ? "stop.fill" : "play.fill")
                    .foregroundStyle(.black)
                    .font(.system(size: 14))
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Text(sound.name)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.black)
                .lineLimit(1)
            
            Spacer()
            
            Menu {
                Button(role: .destructive) {
                    if audioManager.currentlyPlayingID == sound.id { audioManager.stop() }
                    modelContext.delete(sound)
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
                
                Button() {
                    selectedSound = sound
                } label: {
                    Label("Назначить на клавишу", systemImage: "keyboard")
                }
                
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.black)
                    .padding(5)
            }
            .menuStyle(.borderlessButton)
            .colorScheme(.light)
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.black.opacity(0.03))
        .cornerRadius(15)
    }
}

// MARK: - Менеджер Звука
@Observable
class AudioManager: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    var currentlyPlayingID: UUID?
    private var globalMonitor: Any?

    func setupMonitoring(container: ModelContainer) {
        if let gm = globalMonitor { NSEvent.removeMonitor(gm) }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let pressed = self?.format(event) ?? ""
            
            Task { @MainActor in
                let context = container.mainContext
                let descriptor = FetchDescriptor<Item>()
                if let items = try? context.fetch(descriptor),
                   let sound = items.first(where: { $0.keyBinding == pressed }) {
                    self?.play(data: sound.audioData, id: sound.id)
                }
            }
        }
    }

    func play(data: Data, id: UUID) {
        if currentlyPlayingID == id { stop(); return }
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            currentlyPlayingID = id
        } catch { print(error) }
    }

    func stop() {
        audioPlayer?.stop()
        currentlyPlayingID = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentlyPlayingID = nil
    }

    private func format(_ event: NSEvent) -> String {
        var parts: [String] = []
        let f = event.modifierFlags
        if f.contains(.command) { parts.append("⌘") }
        if f.contains(.shift) { parts.append("⇧") }
        if f.contains(.option) { parts.append("⌥") }
        if f.contains(.control) { parts.append("⌃") }
        let special: [UInt16: String] = [53:"ESC", 36:"↩", 48:"TAB", 51:"⌫", 49:"Space"]
        parts.append(special[event.keyCode] ?? (event.charactersIgnoringModifiers?.uppercased() ?? ""))
        return parts.joined()
    }
}

private func importFile(from url: URL, modelContext: ModelContext) {
    guard url.startAccessingSecurityScopedResource() else { return }
    defer { url.stopAccessingSecurityScopedResource() }
    if let data = try? Data(contentsOf: url) {
        modelContext.insert(Item(name: url.lastPathComponent, audioData: data))
        try? modelContext.save()
    }
}

//
//  ContentView.swift
//  SoundPad
//
//  Created by Никита Струкалин on 09.04.2026.
//

import SwiftUI
import Foundation
import SwiftData
import UniformTypeIdentifiers
import AVFoundation

// MARK: - Менеджер Звука
@Observable
class AudioManager: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    var currentlyPlayingID: UUID?

    func play(data: Data, id: UUID) {
        // Если нажат тот же звук, который уже играет — останавливаем
        if currentlyPlayingID == id {
            stop()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentlyPlayingID = id
        } catch {
            print("Ошибка воспроизведения: \(error.localizedDescription)")
        }
    }

    func stop() {
        audioPlayer?.stop()
        currentlyPlayingID = nil
    }

    // Сбрасываем иконку, когда звук доиграл до конца
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentlyPlayingID = nil
    }
}

// MARK: - Основной Интерфейс
struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Item.name) var sounds: [Item]
    
    @State private var audioManager = AudioManager()
    @State private var isImporting: Bool = false
    @State private var searchText = ""
    
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
                        .buttonStyle(.blackGlassCircle) // Твой кастомный стиль
                        .padding(.top)
                    }
                    
                    // ПОЛЕ ПОИСКА
                    TextField("Поиск звука...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.black)
                        .focusable(true)
                        .tint(.black)
                        .padding(10)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(10)
                        .colorScheme(.light)
                        .padding(.horizontal)
                        .padding(.top, 20)

                    
                    // СПИСОК ЗВУКОВ
                    ScrollView(.vertical) {
                        VStack(spacing: 12) {
                            ForEach(filteredSounds) { sound in
                                HStack {
                                    // Кнопка Play / Stop
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
                        .padding()
                    }
                    .scrollIndicators(.visible)
                }
            }
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

// MARK: - Функция импорта
private func importFile(from url: URL, modelContext: ModelContext) {
    guard url.startAccessingSecurityScopedResource() else { return }
    defer { url.stopAccessingSecurityScopedResource() }
    do {
        let data = try Data(contentsOf: url)
        let newItem = Item(name: url.lastPathComponent, audioData: data)
        modelContext.insert(newItem)
        try modelContext.save()
    } catch {
        print("Ошибка при импорте файла: \(error)")
    }
}

#Preview {
    ContentView()
}

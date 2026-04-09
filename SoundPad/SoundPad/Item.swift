//
//  Item.swift
//  SoundPad
//
//  Created by Никита Струкалин on 09.04.2026.
//

import Foundation
import SwiftData

@Model
final class Item: Identifiable {
    var id: UUID
    var name: String
    @Attribute(.externalStorage) var audioData: Data
    
    init(name: String, audioData: Data) {
        self.id = UUID()
        self.name = name
        self.audioData = audioData
    }
}

//
//  Item.swift
//  SoundPad
//
//  Created by Никита Струкалин on 09.04.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID
    var name: String
    var keyBinding: String = ""
    @Attribute(.externalStorage) var audioData: Data

    init(name: String, audioData: Data, keyBinding: String = "") {
        self.id = UUID()
        self.name = name
        self.audioData = audioData
        self.keyBinding = keyBinding
    }
}

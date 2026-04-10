//
//  ButtonStyle.swift
//  SoundPad
//
//  Created by Никита Струкалин on 09.04.2026.
//

import SwiftUI

struct BlackGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 33, height: 33)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.85),
                                Color(white: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: .white.opacity(0.1), radius: 2, x: -1, y: -1)
                    .shadow(color: .black.opacity(0.5), radius: 6, x: 2, y: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BlackGlassButtonStyle {
    static var blackGlassCircle: Self { Self() }
}

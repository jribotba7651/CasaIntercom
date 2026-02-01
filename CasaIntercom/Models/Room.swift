import Foundation
import SwiftUI

struct Room: Identifiable, Equatable {
    let id: UUID
    let name: String
    let emoji: String
    let color: Color

    init(id: UUID = UUID(), name: String, emoji: String, color: Color) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.color = color
    }

    // Predefined rooms with friendly colors
    static let defaultRooms: [Room] = [
        Room(name: "Sala", emoji: "🛋️", color: .blue),
        Room(name: "Cocina", emoji: "🍳", color: .orange),
        Room(name: "Cuarto Principal", emoji: "🛏️", color: .purple),
        Room(name: "Cuarto del Bebé", emoji: "👶", color: .pink),
        Room(name: "Oficina", emoji: "💻", color: .green),
        Room(name: "Garaje", emoji: "🚗", color: .gray)
    ]
}

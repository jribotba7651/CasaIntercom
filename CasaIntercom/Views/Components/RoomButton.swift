import SwiftUI

struct RoomButton: View {
    let room: Room
    let isTalking: Bool
    let onTalkingChanged: (Bool) -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 12) {
            // Emoji grande
            Text(room.emoji)
                .font(.system(size: 50))

            // Nombre de la habitación
            Text(room.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    isTalking
                        ? room.color.opacity(1.0)
                        : room.color.opacity(0.7)
                )
                .shadow(
                    color: isTalking ? room.color.opacity(0.8) : .clear,
                    radius: isTalking ? 20 : 0
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    isTalking ? Color.white : Color.clear,
                    lineWidth: 4
                )
        )
        .scaleEffect(isTalking ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isTalking)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isTalking {
                        onTalkingChanged(true)
                        hapticFeedback()
                    }
                }
                .onEnded { _ in
                    onTalkingChanged(false)
                }
        )
    }

    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    RoomButton(
        room: Room(name: "Sala", emoji: "🛋️", color: .blue),
        isTalking: false,
        onTalkingChanged: { _ in }
    )
    .frame(width: 160, height: 160)
    .padding()
    .background(Color.black)
}

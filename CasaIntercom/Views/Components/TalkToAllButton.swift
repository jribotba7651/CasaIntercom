import SwiftUI

struct TalkToAllButton: View {
    let isTalking: Bool
    @ObservedObject var languageManager: LanguageManager
    let onTalkingChanged: (Bool) -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Megaphone icon
            Image(systemName: isTalking ? "speaker.wave.3.fill" : "megaphone.fill")
                .font(.system(size: 32))
                .foregroundColor(.white)
                .symbolEffect(.bounce, value: isTalking)

            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.talkToAll)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(isTalking ? languageManager.transmitting : languageManager.holdToTalk)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isTalking ? Color.red : Color.red.opacity(0.8))
                .shadow(
                    color: isTalking ? Color.red.opacity(0.6) : .clear,
                    radius: isTalking ? 15 : 0
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isTalking ? Color.white : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isTalking ? 0.98 : 1.0)
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
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    VStack {
        TalkToAllButton(isTalking: false, languageManager: LanguageManager.shared, onTalkingChanged: { _ in })
        TalkToAllButton(isTalking: true, languageManager: LanguageManager.shared, onTalkingChanged: { _ in })
    }
    .padding()
    .background(Color.black)
}

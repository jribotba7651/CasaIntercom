import SwiftUI

struct PushToTalkButton: View {
    var isTransmitting: Bool
    var onPress: () -> Void
    var onRelease: () -> Void
    
    @State private var isPressed = false
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0.5
    
    var body: some View {
        ZStack {
            // Ripple Effect
            if isTransmitting {
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                    .onAppear {
                        withAnimation(Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                            self.rippleScale = 1.5
                            self.rippleOpacity = 0.0
                        }
                    }
            }
            
            // Button Core
            Circle()
                .fill(isPressed ? Color.orange : Color.blue)
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(radius: 10)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !self.isPressed {
                                self.isPressed = true
                                self.onPress()
                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                        }
                        .onEnded { _ in
                            self.isPressed = false
                            self.onRelease()
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                            generator.impactOccurred()
                            
                            // Reset ripple
                            self.rippleScale = 1.0
                            self.rippleOpacity = 0.5
                        }
                )
        }
        .frame(width: 200, height: 200) // Container
    }
}

import SwiftUI
import MultipeerConnectivity

struct IntercomGridView: View {
    @ObservedObject private var audioManager = AudioManager.shared
    @ObservedObject private var multipeerManager = MultipeerConnectivityManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    @State private var talkingToPeer: MCPeerID? = nil
    @State private var talkingToAll: Bool = false
    @State private var showSettings: Bool = false

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // Colors for devices (cycle through these)
    let deviceColors: [Color] = [.blue, .orange, .purple, .pink, .green, .cyan, .indigo, .mint]

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header
                    headerView

                    // Device grid or empty state
                    if multipeerManager.connectedPeers.isEmpty {
                        emptyStateView
                    } else {
                        deviceGridView
                    }

                    // Talk to all button (only show if there are connected peers)
                    if !multipeerManager.connectedPeers.isEmpty {
                        TalkToAllButton(
                            isTalking: talkingToAll,
                            languageManager: languageManager,
                            onTalkingChanged: { talking in
                                handleTalkToAll(talking: talking)
                            }
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(languageManager: languageManager)
            }
            .onAppear {
                multipeerManager.start()
            }
            .onDisappear {
                multipeerManager.stop()
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.appTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding(12)
                    .background(Circle().fill(Color.gray.opacity(0.2)))
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated searching icon
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 80))
                .foregroundColor(.gray)
                .symbolEffect(.pulse)

            Text(languageManager.searchingDevices)
                .font(.title2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Text(languageManager.noDevicesFound)
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Device Grid
    private var deviceGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(multipeerManager.connectedPeers.enumerated()), id: \.element.id) { index, peer in
                    DeviceButton(
                        peer: peer,
                        color: deviceColors[index % deviceColors.length],
                        isTalking: talkingToPeer == peer.id,
                        onTalkingChanged: { talking in
                            handleDeviceTalking(peer: peer, talking: talking)
                        }
                    )
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Status Text
    private var statusText: String {
        if talkingToAll {
            return languageManager.broadcastingToAll
        } else if let peerId = talkingToPeer,
                  let peer = multipeerManager.connectedPeers.first(where: { $0.id == peerId }) {
            return "🎤 \(languageManager.talkingTo) \(peer.name)..."
        } else if multipeerManager.connectedPeers.isEmpty {
            return languageManager.searchingDevices
        } else {
            return languageManager.tapToTalk
        }
    }

    // MARK: - Actions
    private func handleDeviceTalking(peer: PeerDevice, talking: Bool) {
        if talking {
            talkingToAll = false
            talkingToPeer = peer.id
            multipeerManager.targetPeer = peer
            audioManager.startRecording()
        } else {
            talkingToPeer = nil
            multipeerManager.targetPeer = nil
            audioManager.stopRecording()
        }
    }

    private func handleTalkToAll(talking: Bool) {
        if talking {
            talkingToPeer = nil
            talkingToAll = true
            multipeerManager.targetPeer = nil // nil means broadcast to all
            audioManager.startRecording()
        } else {
            talkingToAll = false
            audioManager.stopRecording()
        }
    }
}

// MARK: - Device Button Component
struct DeviceButton: View {
    let peer: PeerDevice
    let color: Color
    let isTalking: Bool
    let onTalkingChanged: (Bool) -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Device icon
            Image(systemName: deviceIcon)
                .font(.system(size: 50))
                .foregroundColor(.white)

            // Device name
            Text(peer.name)
                .font(.title3)
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
                .fill(isTalking ? color : color.opacity(0.7))
                .shadow(
                    color: isTalking ? color.opacity(0.8) : .clear,
                    radius: isTalking ? 20 : 0
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isTalking ? Color.white : Color.clear, lineWidth: 4)
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

    private var deviceIcon: String {
        let name = peer.name.lowercased()
        if name.contains("homepod") {
            return "homepod.fill"
        } else if name.contains("iphone") {
            return "iphone"
        } else if name.contains("ipad") {
            return "ipad"
        } else if name.contains("mac") {
            return "desktopcomputer"
        } else if name.contains("tv") || name.contains("apple tv") {
            return "appletv.fill"
        } else {
            return "speaker.wave.2.fill"
        }
    }

    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// Extension to get array length safely
extension Array {
    var length: Int { count }
}

#Preview {
    IntercomGridView()
}

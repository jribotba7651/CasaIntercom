import SwiftUI

struct IntercomView: View {
    @ObservedObject private var multipeerManager = MultipeerConnectivityManager.shared
    @State private var isSettingsPresented = false
    @State private var selectedPeerId: String? = nil // ID of selected peer for direct Application
    
    // Grid Setup
    let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Status Bar / Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Casa Intercom")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            HStack {
                                Circle()
                                    .fill(multipeerManager.connectedPeers.isEmpty ? Color.orange : Color.green)
                                    .frame(width: 10, height: 10)
                                Text(multipeerManager.connectedPeers.isEmpty ? "Searching..." : "\(multipeerManager.connectedPeers.count) Active Devices")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        
                        Button(action: { isSettingsPresented = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground).opacity(0.8))
                    
                    // Main Grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            // Current device card (optional, but good for confirmation)
                            // Maybe just networked devices
                            
                            ForEach(multipeerManager.connectedPeers) { peer in
                                DeviceCard(device: peer)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedPeerId == peer.id.displayName ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        withAnimation {
                                            if selectedPeerId == peer.id.displayName {
                                                selectedPeerId = nil // Deselect (Broadcast)
                                                multipeerManager.targetPeer = nil
                                            } else {
                                                selectedPeerId = peer.id.displayName
                                                multipeerManager.targetPeer = peer
                                            }
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Bottom Control
                    VStack {
                        if let selectedId = selectedPeerId {
                            Text("Talking to \(selectedId)")
                                .font(.headline)
                                .foregroundColor(.blue)
                        } else {
                            Text("Broadcast to All")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        PushToTalkButton(
                            isTransmitting: AudioManager.shared.isRecording, // We need to expose this state? Or just trust UI state. 
                            // Actually pure UI state `isTransmitting` might be enough for visual, but better to check manager. 
                            // Since `PushToTalkButton` manages its own `isPressed`, we pass that state out or just bind it.
                            // The button has its own internal state. Let's send actions.
                            onPress: {
                                AudioManager.shared.startRecording()
                            },
                            onRelease: {
                                AudioManager.shared.stopRecording()
                            }
                        )
                    }
                    .padding(.bottom, 40)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemBackground).opacity(0), Color(UIColor.systemBackground)]), startPoint: .top, endPoint: .bottom)
                            .frame(height: 150)
                    )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView(languageManager: LanguageManager.shared)
            }
        }
        .onAppear {
            multipeerManager.start()
        }
    }
}

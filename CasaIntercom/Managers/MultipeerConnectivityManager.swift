import Foundation
import MultipeerConnectivity
import Combine

class MultipeerConnectivityManager: NSObject, ObservableObject {
    static let shared = MultipeerConnectivityManager()

    private let serviceType = "casa-intercom"
    private var myPeerId: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!

    @Published var connectedPeers: [PeerDevice] = []
    @Published var targetPeer: PeerDevice? = nil

    // Track invitations
    private var invitedPeers: Set<String> = []
    private var isConnecting = false

    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }

    private override init() {
        // Use a unique name to avoid conflicts
        let deviceName = UIDevice.current.name
        let uniqueId = String(UIDevice.current.identifierForVendor?.uuidString.prefix(4) ?? "0000")
        let storedName = UserDefaults.standard.string(forKey: "userName") ?? "\(deviceName)-\(uniqueId)"
        self.userName = storedName

        super.init()

        setupSession()

        // Setup Audio Manager callback
        AudioManager.shared.onAudioData = { [weak self] data in
            self?.sendVoice(data: data)
        }

        print("MultipeerConnectivityManager initialized as: \(userName)")
    }

    private func setupSession() {
        myPeerId = MCPeerID(displayName: userName)

        // Use .required encryption for stable connections
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func start() {
        print("Starting peer discovery as: \(myPeerId.displayName)")
        invitedPeers.removeAll()
        isConnecting = false
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func stop() {
        print("Stopping peer discovery...")
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }

    func sendVoice(data: Data) {
        guard !session.connectedPeers.isEmpty else {
            return
        }

        let peersToSend: [MCPeerID]
        if let target = targetPeer {
            peersToSend = [target.id]
        } else {
            peersToSend = session.connectedPeers
        }

        guard !peersToSend.isEmpty else { return }

        do {
            try session.send(data, toPeers: peersToSend, with: .reliable)
        } catch {
            print("❌ Send error: \(error.localizedDescription)")
        }
    }

    func updateIdentity() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupSession()
            self?.start()
        }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerConnectivityManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch state {
            case .connected:
                print("✅ CONNECTED to \(peerID.displayName)")
                self.isConnecting = false
                self.invitedPeers.remove(peerID.displayName)

                if !self.connectedPeers.contains(where: { $0.id == peerID }) {
                    let newPeer = PeerDevice(id: peerID, name: peerID.displayName, status: .connected)
                    self.connectedPeers.append(newPeer)
                }

            case .notConnected:
                print("❌ DISCONNECTED from \(peerID.displayName)")
                self.isConnecting = false
                self.invitedPeers.remove(peerID.displayName)
                self.connectedPeers.removeAll { $0.id == peerID }

            case .connecting:
                print("🔄 CONNECTING to \(peerID.displayName)")
                self.isConnecting = true

            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("📥 Received \(data.count) bytes from \(peerID.displayName)")
        AudioManager.shared.playAudio(data: data)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📥 Received invitation from \(peerID.displayName)")

        // Always accept
        invitationHandler(true, self.session)
        print("✅ Accepted invitation from \(peerID.displayName)")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Advertise error: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerConnectivityManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔍 Found peer: \(peerID.displayName)")

        // Skip if already connected
        if session.connectedPeers.contains(peerID) {
            print("   Already connected")
            return
        }

        // Skip if already invited
        if invitedPeers.contains(peerID.displayName) {
            print("   Already invited")
            return
        }

        // Skip if currently connecting
        if isConnecting {
            print("   Already connecting to someone")
            return
        }

        // Use name comparison to decide who invites (deterministic)
        // The device with the "smaller" name sends the invite
        if myPeerId.displayName <= peerID.displayName {
            // Add random delay (0-500ms) to avoid exact simultaneous invites
            let delay = Double.random(in: 0...0.5)
            print("📤 Will invite \(peerID.displayName) in \(Int(delay*1000))ms")

            invitedPeers.insert(peerID.displayName)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }

                // Double-check we're not already connected
                if !self.session.connectedPeers.contains(peerID) && !self.isConnecting {
                    print("📤 Inviting \(peerID.displayName) now")
                    browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 30)
                } else {
                    print("   Skipping invite - already connected or connecting")
                }
            }
        } else {
            print("⏳ Waiting for \(peerID.displayName) to invite me")
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("👋 Lost peer: \(peerID.displayName)")
        invitedPeers.remove(peerID.displayName)
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Browse error: \(error.localizedDescription)")
    }
}

import Foundation
import MultipeerConnectivity

struct PeerDevice: Identifiable, Equatable {
    let id: MCPeerID
    let name: String
    var status: ConnectionStatus
    
    enum ConnectionStatus {
        case connected
        case connecting
        case notConnected
    }
    
    static func == (lhs: PeerDevice, rhs: PeerDevice) -> Bool {
        return lhs.id == rhs.id && lhs.status == rhs.status
    }
}

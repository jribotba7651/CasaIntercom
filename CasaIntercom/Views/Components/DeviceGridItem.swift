import SwiftUI

struct DeviceCard: View {
    let device: PeerDevice
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            // Text Info
            VStack(spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(device.status == .connected ? "Online" : "Connecting...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Status Dot
            HStack {
                Circle()
                    .fill(device.status == .connected ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(device.status == .connected ? "Ready" : "Offline") // redundant but requested "online status (green/gray dot)"
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 140, minHeight: 160)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

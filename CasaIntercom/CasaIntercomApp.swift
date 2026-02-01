import SwiftUI

@main
struct CasaIntercomApp: App {
    // Keep audio manager alive and setup early
    init() {
        // Trigger singleton init
        _ = AudioManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            IntercomGridView()
                .preferredColorScheme(.dark)
        }
    }
}

import SwiftUI

@main
struct MobileCallShieldApp: App {
    // 1. Create a single instance of your SessionStore for the entire app
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 2. Inject it into the environment so all child views can access it
                .environmentObject(session)
        }
    }
}

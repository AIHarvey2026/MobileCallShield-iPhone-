import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some View {
        if isLoggedIn {
            MainDashboardView(isLoggedIn: $isLoggedIn)
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}

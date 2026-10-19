import Foundation
import Combine

class SessionStore: ObservableObject {
    @Published var userId: Int {
        didSet {
            UserDefaults.standard.set(userId, forKey: "userId")
            print("[DEBUG - SessionStore] userId updated and saved to storage: \(userId)")
        }
    }
    
    @Published var isLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
            print("[DEBUG - SessionStore] isLoggedIn status changed to: \(isLoggedIn)")
        }
    }

    init() {
        let storedId = UserDefaults.standard.integer(forKey: "userId")
        // Default to 1 if no user ID is stored yet
        self.userId = storedId == 0 ? 1 : storedId
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        print("[DEBUG - SessionStore] Initialized. Current active userId: \(self.userId) | Logged In: \(self.isLoggedIn)")
    }
    
    func login(userId: Int) {
        self.userId = userId
        self.isLoggedIn = true
        print("[DEBUG - SessionStore] 🟢 User successfully logged in. Assigned userId: \(userId)")
    }
    
    func logout() {
        self.userId = 1
        self.isLoggedIn = false
        print("[DEBUG - SessionStore] 🔴 User logged out. Reset to default userId: 1")
    }
}

// File Name: SessionStore.swift

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

    @Published var assignedTwilioNumber: String {
        didSet {
            UserDefaults.standard.set(assignedTwilioNumber, forKey: "PREF_TWILIO_NUMBER")
            print("[DEBUG - SessionStore] assignedTwilioNumber updated and saved: \(assignedTwilioNumber)")
        }
    }

    init() {
        let storedId = UserDefaults.standard.integer(forKey: "userId")
        // Default to 1 if no user ID is stored yet
        self.userId = storedId == 0 ? 1 : storedId
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.assignedTwilioNumber = UserDefaults.standard.string(forKey: "PREF_TWILIO_NUMBER") ?? "Not Assigned"
        
        print("[DEBUG - SessionStore] Initialized. Active userId: \(self.userId) | Logged In: \(self.isLoggedIn) | Twilio Number: \(self.assignedTwilioNumber)")
    }
    
    func login(userId: Int) {
        self.userId = userId
        self.isLoggedIn = true
        print("[DEBUG - SessionStore] 🟢 User successfully logged in. Assigned userId: \(userId)")
        
        // Automatically fetch the latest profile data (including Twilio number) upon login
        fetchUserProfile()
    }
    
    func logout() {
        self.userId = 1
        self.isLoggedIn = false
        self.assignedTwilioNumber = "Not Assigned"
        UserDefaults.standard.removeObject(forKey: "PREF_TWILIO_NUMBER")
        print("[DEBUG - SessionStore] 🔴 User logged out. Reset to default userId: 1")
    }

    /// Dynamically fetches user profile from the Render backend and updates the assigned Twilio number
    func fetchUserProfile(completion: ((String?) -> Void)? = nil) {
        let baseUrl = "https://mobilecallshield-backend.onrender.com"
        guard let url = URL(string: "\(baseUrl)/api/user/profile?userId=\(userId)") else {
            completion?(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let userObj = json["user"] as? [String: Any] else {
                DispatchQueue.main.async {
                    completion?(self?.assignedTwilioNumber)
                }
                return
            }

            let freshNumber = userObj["assignedTwilioNumber"] as? String
                ?? userObj["twilio_screening_number"] as? String

            DispatchQueue.main.async {
                if let number = freshNumber, !number.isEmpty, number != "null" {
                    self.assignedTwilioNumber = number
                }
                completion?(self.assignedTwilioNumber)
                print("[DEBUG - SessionStore] Profile fetched successfully. Twilio Number: \(self.assignedTwilioNumber)")
            }
        }.resume()
    }
}

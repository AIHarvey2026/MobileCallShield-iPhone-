import Foundation
import CallKit
import Combine

class CallSyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncStatus = "Not Synced"

    func syncScamDatabase() {
        isSyncing = true
        
        guard let url = URL(string: "https://your-backend-url.onrender.com/api/scam-numbers") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isSyncing = false
                
                guard let data = data, error == nil else {
                    self.lastSyncStatus = "Sync Failed: \(error?.localizedDescription ?? "Unknown")"
                    return
                }
                
                do {
                    let numbers = try JSONDecoder().decode([Int64].self, from: data)
                    
                    // Save to Shared App Group container
                    let sharedDefaults = UserDefaults(suiteName: "group.com.AlHarvey.SeniorScamShield")
                    sharedDefaults?.set(numbers, forKey: "cachedScamNumbers")
                    
                    // Reload CallKit extension
                    CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.AlHarvey.SeniorScamShield.MobileCallShieldExtension") { error in
                        if let error = error {
                            print("Failed to reload CallKit extension: \(error.localizedDescription)")
                            self.lastSyncStatus = "CallKit Reload Failed"
                        } else {
                            self.lastSyncStatus = "Successfully Synced & Reloaded"
                        }
                    }
                } catch {
                    self.lastSyncStatus = "Decoding Error"
                }
            }
        }.resume()
    }
}

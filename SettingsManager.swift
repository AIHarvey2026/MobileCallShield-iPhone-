import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var isCallShieldEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCallShieldEnabled, forKey: "isCallShieldEnabled")
        }
    }
    
    init() {
        self.isCallShieldEnabled = UserDefaults.standard.object(forKey: "isCallShieldEnabled") as? Bool ?? true
    }
}

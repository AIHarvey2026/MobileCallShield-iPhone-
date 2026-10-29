import Foundation
import MessageUI

struct GuardianNotifier {
    /// Sends an emergency SMS alert to the guardian via backend Twilio dispatch
    static func sendBackendSMSAlert(userId: Int, guardianPhone: String, message: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/guardians/send-alert") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "userId": userId,
            "guardianPhone": guardianPhone,
            "alertMessage": message
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                let success = (response as? HTTPURLResponse)?.statusCode == 200
                completion(success)
            }
        }.resume()
    }
}

import Foundation
import SwiftUI
import Combine

// MARK: - Models
struct Guardian: Identifiable, Codable {
    let id: Int?
    let userId: Int?
    let guardian_name: String
    let guardian_phone: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case guardian_name
        case guardian_phone
    }
}

// MARK: - Network Manager for Guardians / Trusted Contacts
class GuardianService: ObservableObject {
    @Published var guardians: [Guardian] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let baseURL = "https://mobilecallshield-backend.onrender.com/api/guardians"

    // 1. Fetch Guardians for User
    func fetchGuardians(userId: Int) {
        isLoading = true
        guard let url = URL(string: "\(baseURL)/\(userId)") else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("❌ Fetch error: \(error)")
                    return
                }

                guard let data = data else { return }
                
                // Debug response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📡 Guardians Response: \(jsonString)")
                }

                do {
                    let decoded = try JSONDecoder().decode([Guardian].self, from: data)
                    self?.guardians = decoded
                } catch {
                    print("❌ Decode error: \(error)")
                    self?.errorMessage = error.localizedDescription
                }
            }
        }.resume()
    }

    // 2. Add a Trusted Contact / Guardian
    func addGuardian(userId: Int, name: String, phone: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "guardian_name": name,
            "guardian_phone": phone
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Request serialization error: \(error)")
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Add error: \(error)")
                    completion(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Add Status Code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        // Refresh the list after adding
                        self?.fetchGuardians(userId: userId)
                        completion(true)
                        return
                    }
                }
                completion(false)
            }
        }.resume()
    }

    // 3. Delete a Trusted Contact / Guardian
    func deleteGuardian(id: Int, userId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Delete error: \(error)")
                    completion(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Delete Status Code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 {
                        // Refresh the list after deleting
                        self?.fetchGuardians(userId: userId)
                        completion(true)
                        return
                    }
                }
                completion(false)
            }
        }.resume()
    }
}


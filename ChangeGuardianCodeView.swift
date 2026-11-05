import Foundation
import SwiftUI

// MARK: - Change Guardian Code Verification Modal View
struct ChangeGuardianCodeView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: Int
    
    @State private var currentCode: String = ""
    @State private var newCode: String = ""
    @State private var confirmNewCode: String = ""
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""

    private var isValidInput: Bool {
        !currentCode.isEmpty &&
        !newCode.isEmpty &&
        !confirmNewCode.isEmpty &&
        (newCode == confirmNewCode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Current Guardian Code")) {
                    SecureField("Current Guardian Code", text: $currentCode)
                        .keyboardType(.numberPad)
                }

                Section(
                    header: Text("New Guardian Code"),
                    footer: Text(newCode.isEmpty || confirmNewCode.isEmpty ? "" : (newCode == confirmNewCode ? "✓ Codes match" : "❌ New codes do not match"))
                ) {
                    SecureField("New Guardian Code", text: $newCode)
                        .keyboardType(.numberPad)
                    
                    SecureField("Confirm New Guardian Code", text: $confirmNewCode)
                        .keyboardType(.numberPad)
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage).foregroundColor(.red).font(.caption)
                    }
                }

                if !successMessage.isEmpty {
                    Section {
                        Text(successMessage).foregroundColor(.green).font(.caption)
                    }
                }

                Section {
                    Button(action: submitGuardianCodeChange) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("OK").fontWeight(.bold).foregroundColor(.white)
                            }
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                    .background(isValidInput && !isLoading ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .disabled(!isValidInput || isLoading)
                }
            }
            .navigationTitle("Change Guardian Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submitGuardianCodeChange() {
        isLoading = true
        errorMessage = ""
        successMessage = ""

        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/settings/update-guardian-code") else {
            isLoading = false
            errorMessage = "Invalid server URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "userId": userId,
            "currentGuardianCode": currentCode.trimmingCharacters(in: .whitespaces),
            "newGuardianCode": newCode.trimmingCharacters(in: .whitespaces)
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    errorMessage = "No response from server."
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let success = json["success"] as? Bool ?? false
                        if success {
                            successMessage = json["message"] as? String ?? "Guardian Code updated successfully!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                dismiss()
                            }
                        } else {
                            errorMessage = json["error"] as? String ?? "Failed to update Guardian Code."
                        }
                    }
                } catch {
                    errorMessage = "Failed to parse response."
                }
            }
        }.resume()
    }
}

import SwiftUI

struct PasscodeSettingsView: View {
    @State private var currentPasscode: String = ""
    @State private var newPasscode: String = ""
    @State private var confirmPasscode: String = ""
    
    @State private var isLoading: Bool = false
    @State private var message: String = ""
    @State private var isError: Bool = false
    
    // Retrieve logged-in user ID from UserDefaults
    private var userId: Int {
        return UserDefaults.standard.integer(forKey: "loggedInUserId")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Passcode Settings"), footer: Text("Trusted callers and family members must speak this word or phrase after calling your protected number.")) {
                    SecureField("New Passcode / Passphrase", text: $newPasscode)
                    SecureField("Confirm New Passcode", text: $confirmPasscode)
                    
                    Button(action: {
                        updatePasscode()
                    }) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save New Passcode")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newPasscode.isEmpty || newPasscode != confirmPasscode || isLoading)
                }
                
                if !message.isEmpty {
                    Section {
                        Text(message)
                            .foregroundColor(isError ? .red : .green)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Passcode Shield")
        }
    }
    
    // MARK: - API Call to Update Passcode
    private func updatePasscode() {
        guard newPasscode == confirmPasscode, !newPasscode.isEmpty else {
            isError = true
            message = "Passcodes do not match."
            return
        }
        
        isLoading = true
        message = ""
        
        guard let url = URL(string: "https://mobile-call-shield.onrender.com/api/user/passcode") else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "passcode": newPasscode
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.isError = true
                    self.message = "Error: \(error.localizedDescription)"
                    return
                }
                
                self.isError = false
                self.message = "Passcode updated successfully!"
                self.newPasscode = ""
                self.confirmPasscode = ""
            }
        }.resume()
    }
}

#Preview {
    PasscodeSettingsView()
}

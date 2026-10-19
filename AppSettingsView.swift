import SwiftUI

struct AppSettingsView: View {
    @AppStorage("loggedInUserId") private var loggedInUserId: Int = 1
    
    // Guardian Shield State
    @State private var isShieldEnabled: Bool = true
    @State private var showingShieldPinAlert: Bool = false
    @State private var togglePinInput: String = ""
    @State private var pendingShieldState: Bool = true
    
    // Change PIN State
    @State private var showingChangePinAlert: Bool = false
    @State private var currentPinInput: String = ""
    @State private var newPinInput: String = ""
    @State private var confirmNewPinInput: String = ""
    
    // Change Passcode Phrase State
    @State private var showingPasscodeAlert: Bool = false
    @State private var passcodePinInput: String = ""
    @State private var newPasscodePhrase: String = ""
    
    // Status Messages
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading: Bool = false

    var body: some View {
        Form {
            // 1. Guardian Shield Toggle
            Section(
                header: Text("Shield Controls"),
                footer: Text("No Guardian assigned: Account owner can turn off Guardian Shield. If Guardians, only primary Guardian can turn off Guardian Shield.")
            ) {
                Toggle("Guardian Shield Active", isOn: Binding(
                    get: { isShieldEnabled },
                    set: { newValue in
                        pendingShieldState = newValue
                        if !newValue {
                            // Instantly call the backend to turn it off without showing the alert popup
                            updateShieldStatus(enabled: false, pin: "")
                        } else {
                            updateShieldStatus(enabled: true, pin: "")
                        }
                    }
                ))
            }
             
            // 2. Security PIN Management Section
            Section(
                header: Text("Security Management"),
                footer: Text("You must enter your current PIN to set a new security PIN.")
            ) {
                Button(action: {
                    showingChangePinAlert = true
                }) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                        Text("Change Owner PIN")
                            .foregroundColor(.primary)
                    }
                }
            }

            // 3. Call Screening Passcode Section
            Section(
                header: Text("Owner Passcode"),
                footer: Text("Visitors must type the exact word or phrase to pass call screening.")
            ) {
                Button(action: {
                    showingPasscodeAlert = true
                }) {
                    HStack {
                        Image(systemName: "textformat")
                            .foregroundColor(.blue)
                        Text("Change Passcode Phrase")
                            .foregroundColor(.primary)
                    }
                }
            }

            // 4. Status Alerts
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
             
            if let success = successMessage {
                Section {
                    Text(success)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Shield Settings")
         
        // --- ALERT 1: Enter PIN to Disable Shield ---
        .alert("Disable Guardian Shield", isPresented: $showingShieldPinAlert) {
            SecureField("Enter Current PIN", text: $togglePinInput)
                .keyboardType(.numberPad)
            Button("Confirm") {
                updateShieldStatus(enabled: pendingShieldState, pin: togglePinInput)
                togglePinInput = ""
            }
            Button("Cancel", role: .cancel) {
                pendingShieldState = isShieldEnabled
                togglePinInput = ""
            }
        } message: {
            Text("Please enter your current Guardian PIN to turn off protection.")
        }
         
        // --- ALERT 2: Change PIN Dialog ---
        .alert("Change Owner PIN", isPresented: $showingChangePinAlert) {
            SecureField("Current PIN", text: $currentPinInput)
                .keyboardType(.numberPad)
            SecureField("New 4-Digit PIN", text: $newPinInput)
                .keyboardType(.numberPad)
            SecureField("Confirm New PIN", text: $confirmNewPinInput)
                .keyboardType(.numberPad)
                 
            Button("Update PIN") {
                validateAndUpdatePin()
            }
            Button("Cancel", role: .cancel) {
                clearPinInputs()
            }
        } message: {
            Text("Enter your current PIN and your new PIN.")
        }

        // --- ALERT 3: Change Passcode Phrase Dialog ---
        .alert("Change Passcode Phrase", isPresented: $showingPasscodeAlert) {
            SecureField("Owner PIN", text: $passcodePinInput)
                .keyboardType(.numberPad)
            TextField("New Word or Phrase", text: $newPasscodePhrase)
                .textInputAutocapitalization(.words)
            
            Button("Update Passcode") {
                updatePasscodeOnBackend(pin: passcodePinInput, passcode: newPasscodePhrase)
                passcodePinInput = ""
                newPasscodePhrase = ""
            }
            Button("Cancel", role: .cancel) {
                passcodePinInput = ""
                newPasscodePhrase = ""
            }
        } message: {
            Text("Enter your Owner PIN and the new word or phrase visitors must speak.")
        }
    }

    private func validateAndUpdatePin() {
        guard !currentPinInput.isEmpty else {
            errorMessage = "Current PIN is required."
            clearPinInputs()
            return
        }
         
        guard newPinInput.count >= 4 else {
            errorMessage = "New PIN must be at least 4 digits."
            clearPinInputs()
            return
        }
         
        guard newPinInput == confirmNewPinInput else {
            errorMessage = "New PINs do not match."
            clearPinInputs()
            return
        }
         
        updatePinOnBackend(current: currentPinInput, new: newPinInput)
        clearPinInputs()
    }
     
    private func clearPinInputs() {
        currentPinInput = ""
        newPinInput = ""
        confirmNewPinInput = ""
    }

    private func updateShieldStatus(enabled: Bool, pin: String) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/user/toggle-shield") else { return }
         
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         
        let body: [String: Any] = [
            "userId": loggedInUserId,
            "isEnabled": enabled,
            "pin": pin
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    isShieldEnabled = enabled
                    successMessage = "Shield status updated successfully."
                    errorMessage = nil
                } else {
                    isShieldEnabled = !enabled
                    errorMessage = "Incorrect PIN or server error."
                    successMessage = nil
                }
            }
        }.resume()
    }
     
    private func updatePinOnBackend(current: String, new: String) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/user/update-pin") else { return }
         
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         
        let body: [String: Any] = [
            "userId": loggedInUserId,
            "currentPin": current,
            "newPin": new
        ]
        
        print("[DEBUG] Payload userId: \(loggedInUserId)")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    successMessage = "Guardian PIN changed successfully!"
                    errorMessage = nil
                } else {
                    errorMessage = "Failed to update PIN. Please check your current PIN."
                    successMessage = nil
                }
            }
        }.resume()
    }

    private func updatePasscodeOnBackend(pin: String, passcode: String) {
        guard !pin.isEmpty, !passcode.isEmpty else {
            errorMessage = "PIN and new passcode phrase are required."
            return
        }
        
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/settings/update-passcode") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": loggedInUserId,
            "pin": pin,
            "newPasscode": passcode
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    successMessage = "Passcode phrase updated successfully!"
                    errorMessage = nil
                } else {
                    errorMessage = "Failed to update passcode. Check your Owner PIN."
                    successMessage = nil
                }
            }
        }.resume()
    }
}

#Preview {
    NavigationStack {
        AppSettingsView()
    }
}

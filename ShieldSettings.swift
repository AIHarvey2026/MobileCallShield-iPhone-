import Foundation
import SwiftUI
import Combine

struct ShieldSettings: View {
    @AppStorage("loggedInUserId") private var loggedInUserId: Int = 0
    @AppStorage("isGuardianShieldActive") private var isGuardianShieldActive: Bool = true
    
    // Shield Toggle Passcode Prompt & Guardian check
    @State private var showPinPrompt: Bool = false
    @State private var pinPromptInput: String = ""
    @State private var hasActiveGuardians: Bool = false

    // Modal Presentation States
    @State private var showChangeOwnerPinSheet: Bool = false
    @State private var showChangePasscodeSheet: Bool = false

    var body: some View {
        Form {
            // MARK: - Shield Controls Section
            Section(
                header: Text("Shield Controls"),
                footer: Text(hasActiveGuardians ? "Only active guardians can turn off Guardian Shield." : "No Guardian assigned: Account owner can turn off Guardian Shield.")
            ) {
                Toggle(isOn: Binding(
                    get: { isGuardianShieldActive },
                    set: { newValue in
                        if !newValue {
                            if !hasActiveGuardians {
                                toggleShieldOnBackend(isEnabled: false, pin: "")
                            } else {
                                pinPromptInput = ""
                                showPinPrompt = true
                            }
                        } else {
                            toggleShieldOnBackend(isEnabled: true, pin: "")
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Guardian Shield Active")
                            .font(.headline)
                        Text(isGuardianShieldActive ? "Call screening is actively protecting your device." : "Call screening is currently disabled.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.green)
            }

            // MARK: - Security Management (Owner PIN)
            Section(header: Text("Security Management")) {
                Button(action: {
                    showChangeOwnerPinSheet = true
                }) {
                    HStack {
                        Label("Change Owner PIN", systemImage: "key.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }

            // MARK: - Owner Passcode (Voice Screening)
            Section(
                header: Text("Owner Passcode"),
                footer: Text("Visitors must type or speak the exact word or phrase to pass call screening.")
            ) {
                Button(action: {
                    showChangePasscodeSheet = true
                }) {
                    HStack {
                        Label("Change Passcode Phrase", systemImage: "textformat")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Shield Settings")
        .onAppear {
            checkGuardiansStatus()
        }
        .sheet(isPresented: $showChangeOwnerPinSheet) {
            ChangeOwnerPinView(userId: loggedInUserId)
        }
        .sheet(isPresented: $showChangePasscodeSheet) {
            ChangePasscodePhraseView(userId: loggedInUserId)
        }
        // MARK: - PIN Verification Alert for Shield Toggle
        .alert("Verify Passcode", isPresented: $showPinPrompt) {
            SecureField("Guardian Passcode", text: $pinPromptInput)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { }
            Button("Disable Shield", role: .destructive) {
                toggleShieldOnBackend(isEnabled: false, pin: pinPromptInput)
            }
        } message: {
            Text("Enter the Guardian Passcode to disable call screening protection.")
        }
    }

    // MARK: - Check if Guardians Exist
    private func checkGuardiansStatus() {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/trusted-contacts/\(loggedInUserId)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                let guardianFound = array.contains { contact in
                    let isGuardian = contact["is_guardian"] as? Bool ?? false
                    return isGuardian
                }
                DispatchQueue.main.async {
                    self.hasActiveGuardians = guardianFound
                }
            }
        }.resume()
    }

    // MARK: - Toggle Shield Backend Call
    private func toggleShieldOnBackend(isEnabled: Bool, pin: String) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/user/toggle-shield") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": loggedInUserId,
            "isEnabled": isEnabled,
            "pin": pin.trimmingCharacters(in: .whitespaces)
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error { return }
                guard let data = data else { return }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let success = json["success"] as? Bool ?? false
                        if success {
                            isGuardianShieldActive = isEnabled
                        }
                    }
                } catch {}
            }
        }.resume()
    }
}

// MARK: - Change Owner PIN Modal View (Double-Verification Flow)
struct ChangeOwnerPinView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: Int

    @State private var currentPin: String = ""
    @State private var newPin: String = ""
    @State private var confirmNewPin: String = ""

    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""

    private var isValidInput: Bool {
        !currentPin.isEmpty &&
        !newPin.isEmpty &&
        !confirmNewPin.isEmpty &&
        (newPin == confirmNewPin)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Owner PIN")) {
                    SecureField("Current Owner PIN", text: $currentPin)
                        .keyboardType(.numberPad)
                }

                Section(
                    header: Text("New Owner PIN"),
                    footer: Text(newPin.isEmpty || confirmNewPin.isEmpty ? "" : (newPin == confirmNewPin ? "✓ PINs match" : "❌ New PINs do not match"))
                ) {
                    SecureField("New Owner PIN", text: $newPin)
                        .keyboardType(.numberPad)

                    SecureField("Confirm New Owner PIN", text: $confirmNewPin)
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
                    Button(action: submitOwnerPinChange) {
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
            .navigationTitle("Change Owner PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submitOwnerPinChange() {
        isLoading = true
        errorMessage = ""
        successMessage = ""

        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/user/update-owner-pin") else {
            isLoading = false
            errorMessage = "Invalid server URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "currentPin": currentPin.trimmingCharacters(in: .whitespaces),
            "newPin": newPin.trimmingCharacters(in: .whitespaces)
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
                            successMessage = json["message"] as? String ?? "Owner PIN updated successfully!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                dismiss()
                            }
                        } else {
                            errorMessage = json["error"] as? String ?? "Failed to update Owner PIN."
                        }
                    }
                } catch {
                    errorMessage = "Failed to parse server response."
                }
            }
        }.resume()
    }
}

// MARK: - Change Passcode Phrase Modal View (Double-Verification Flow)
struct ChangePasscodePhraseView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: Int

    @State private var currentOwnerPin: String = ""
    @State private var newPasscode: String = ""
    @State private var confirmNewPasscode: String = ""

    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""

    private var isValidInput: Bool {
        !currentOwnerPin.isEmpty &&
        !newPasscode.isEmpty &&
        !confirmNewPasscode.isEmpty &&
        (newPasscode == confirmNewPasscode)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Authorization"), footer: Text("Enter your Owner PIN to authorize changing the screening passphrase.")) {
                    SecureField("Current Owner PIN", text: $currentOwnerPin)
                        .keyboardType(.numberPad)
                }

                Section(
                    header: Text("New Passcode Phrase"),
                    footer: Text(newPasscode.isEmpty || confirmNewPasscode.isEmpty ? "" : (newPasscode == confirmNewPasscode ? "✓ Phrases match" : "❌ New phrases do not match"))
                ) {
                    TextField("New Passcode Phrase", text: $newPasscode)
                        .textInputAutocapitalization(.never)

                    TextField("Confirm New Passcode Phrase", text: $confirmNewPasscode)
                        .textInputAutocapitalization(.never)
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
                    Button(action: submitPasscodeChange) {
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
            .navigationTitle("Change Passcode Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func submitPasscodeChange() {
        isLoading = true
        errorMessage = ""
        successMessage = ""

        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/settings/update-passcode") else {
            isLoading = false
            errorMessage = "Invalid server URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "pin": currentOwnerPin.trimmingCharacters(in: .whitespaces),
            "newPasscode": newPasscode.trimmingCharacters(in: .whitespaces)
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
                            successMessage = json["message"] as? String ?? "Passcode Phrase updated successfully!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                dismiss()
                            }
                        } else {
                            errorMessage = json["error"] as? String ?? "Failed to update Passcode Phrase."
                        }
                    }
                } catch {
                    errorMessage = "Failed to parse server response."
                }
            }
        }.resume()
    }
}

#Preview {
    ShieldSettings()
}

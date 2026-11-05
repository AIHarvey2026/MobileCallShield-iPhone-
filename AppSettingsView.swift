// File Name: AppSettingsView.swift

import Foundation
import SwiftUI
import Combine

struct AppSettingsView: View {
    @AppStorage("loggedInUserId") private var loggedInUserId: Int = 1
    @AppStorage("twilioNumber") private var callShieldNumber: String = ""
    @Environment(\.dismiss) private var dismiss
    
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

    // Message Name (Greeting Name) State
    @State private var showingMessageNameAlert: Bool = false
    @State private var currentMessageNameInput: String = ""

    // Deactivate Account State
    @State private var showDeactivateAlert: Bool = false
    @State private var deactivatePinInput: String = ""
    
    // Copy Clipboard Alert State
    @State private var showCopiedAlert: Bool = false

    // Status Messages
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading: Bool = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Status Feedback Banners
                    if let success = successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(success)
                                .font(.system(size: 15, weight: .bold))
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(14)
                    }

                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                                .font(.system(size: 15, weight: .bold))
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(14)
                    }

                    callShieldNumberCard
                    shieldControlsCard
                    securityManagementCard
                    ownerPasscodeCard
                    messageNameCard
                    carrierManagementCard
                }
                .padding(16)
            }
        }
        .navigationTitle("Shield Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                        Text("Back")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .cornerRadius(20)
                }
            }
        }
        .alert("Copied to Clipboard", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your Call Shield Number has been copied.")
        }
         
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

        // --- ALERT 4: Update Greeting Message Name ---
        .alert("Update Greeting Name", isPresented: $showingMessageNameAlert) {
            TextField("e.g. Grandma Mary or Leave Blank", text: $currentMessageNameInput)
                .textInputAutocapitalization(.words)
             
            Button("Update Name") {
                updateMessageNameToBackend(rawMessageName: currentMessageNameInput)
                currentMessageNameInput = ""
            }
            Button("Cancel", role: .cancel) {
                currentMessageNameInput = ""
            }
        } message: {
            Text("Enter the name announced during call screening, or leave blank for complete privacy.")
        }

        // --- ALERT 5: Deactivate Account ---
        .alert("Deactivate Account", isPresented: $showDeactivateAlert) {
            SecureField("Guardian PIN (if required)", text: $deactivatePinInput)
                .keyboardType(.numberPad)
            Button("Deactivate", role: .destructive) {
                deactivatePinInput = ""
            }
            Button("Cancel", role: .cancel) {
                deactivatePinInput = ""
            }
        } message: {
            Text("This will stop your subscription and deactivate your account. Enter your Guardian PIN if assigned.")
        }
    }

    // MARK: - Subviews for Clean Compiler Performance

    private var callShieldNumberCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Call Shield Line")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "shield.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 22, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Call Shield Number")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(callShieldNumber.isEmpty || callShieldNumber == "null" ? "Pending Assignment" : callShieldNumber)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                if !callShieldNumber.isEmpty && callShieldNumber != "null" && callShieldNumber != "Pending Assignment" {
                    Button(action: {
                        UIPasteboard.general.string = callShieldNumber
                        showCopiedAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(10)
                    }
                }
            }

            Text("This is your dedicated protected phone line routing and screening incoming calls.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }

    private var shieldControlsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isShieldEnabled ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "shield.fill")
                        .foregroundColor(isShieldEnabled ? .green : .red)
                        .font(.system(size: 22, weight: .bold))
                }

                Text("Guardian Shield Active")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { isShieldEnabled },
                    set: { newValue in
                        pendingShieldState = newValue
                        updateShieldStatus(enabled: newValue, pin: "")
                    }
                ))
                .labelsHidden()
                .tint(.green)
                .scaleEffect(1.1)
            }

            Text("No Guardian assigned: Account owner can turn off Guardian Shield. If Guardians, only primary Guardian can turn off Guardian Shield.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }

    private var securityManagementCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Security Management")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.secondary)

            Button(action: {
                showingChangePinAlert = true
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 46, height: 46)

                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Change Owner PIN")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)

                        Text("You must enter your current PIN to set a new security PIN.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .bold))
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }

    private var ownerPasscodeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Owner Passcode")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.secondary)

            Button(action: {
                showingPasscodeAlert = true
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 46, height: 46)

                        Image(systemName: "textformat")
                            .foregroundColor(.blue)
                            .font(.system(size: 20, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Change Passcode Phrase")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Visitors must type the exact word or phrase to pass call screening.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .bold))
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }

    private var messageNameCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Greeting Announcement")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.secondary)

            Button(action: {
                showingMessageNameAlert = true
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 46, height: 46)

                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.purple)
                            .font(.system(size: 20, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Change Greeting Name")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Customize the name announced during call screening or clear it for privacy.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .bold))
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }

    private var carrierManagementCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Carrier & Account Management")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.secondary)

            Button(action: {
                // Carrier re-configuration action
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 46, height: 46)

                        Image(systemName: "phone.arrow.right.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20, weight: .bold))
                    }

                    Text("Re-configure Carrier Activation")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .bold))
                }
                .padding(.vertical, 6)
            }

            Divider()

            Button(action: {
                showDeactivateAlert = true
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 46, height: 46)

                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 20, weight: .bold))
                    }

                    Text("Deactivate Account & Cancel Subscription")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.red)

                    Spacer()
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Backend Logic & Validation

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

    private func updateMessageNameToBackend(rawMessageName: String) {
        guard let url = URL(string: "https://mobile-call-shield.onrender.com/api/user/update-message-name") else { return }
         
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         
        let cleaned = rawMessageName.trimmingCharacters(in: .whitespaces)
        let body: [String: Any] = [
            "userId": loggedInUserId,
            "rawMessageName": cleaned.isEmpty ? NSNull() : cleaned
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response from server."
                    return
                }

                guard let data = data, !data.isEmpty else {
                    errorMessage = "Empty response from server (HTTP \(httpResponse.statusCode))."
                    return
                }

                if httpResponse.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let msg = json["message"] as? String {
                        successMessage = msg
                    } else {
                        successMessage = "Greeting name updated successfully!"
                    }
                    errorMessage = nil
                } else {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorStr = json["error"] as? String {
                        errorMessage = errorStr
                    } else if let rawString = String(data: data, encoding: .utf8) {
                        print("Raw non-JSON Server Response: \(rawString)")
                        errorMessage = "Server error (HTTP \(httpResponse.statusCode)). Check backend logs."
                    } else {
                        errorMessage = "Failed with status code \(httpResponse.statusCode)."
                    }
                    successMessage = nil
                }
            }
        }.resume()
    }
}

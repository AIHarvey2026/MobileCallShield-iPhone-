import Foundation
import SwiftUI
import Contacts

// MARK: - Guardian Settings View
struct GuardianSettingsView: View {
    let currentUserId: Int
    @StateObject private var service = GuardianService()

    @State private var showingAddGuardianAlert = false
    @State private var newGuardianName = ""
    @State private var newGuardianPhone = ""
    
    // Sheet presentation state for Guardian Code update
    @State private var showChangeGuardianCodeSheet = false
    
    // One-time phone contacts sync state (persists across app launches)
    @AppStorage("hasSyncedPhoneContacts") private var hasSyncedPhoneContacts: Bool = false
    @State private var isSyncingContacts: Bool = false

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Phone Contacts Sync Section (One-Time Use)
                Section(
                    header: Text("Device Contacts"),
                    footer: Text(hasSyncedPhoneContacts ? "Phone contacts have already been synced to your trusted list." : "Import all contacts from your phone once to populate your trusted list.")
                ) {
                    Button(action: {
                        syncAllPhoneContacts()
                    }) {
                        HStack {
                            Image(systemName: hasSyncedPhoneContacts ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                            Text(hasSyncedPhoneContacts ? "Contacts Already Synced" : "Sync All Phone Contacts")
                                .fontWeight(.bold)
                            Spacer()
                            if isSyncingContacts {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(hasSyncedPhoneContacts || isSyncingContacts)
                    .tint(hasSyncedPhoneContacts ? .gray : .blue)
                }

                // MARK: - Guardian Code Management Section
                Section(
                    header: Text("Guardian Security"),
                    footer: Text("Manage your Guardian Code used to authorize high-security app actions.")
                ) {
                    Button(action: {
                        showChangeGuardianCodeSheet = true
                    }) {
                        HStack {
                            Label("Change Guardian Code", systemImage: "key.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }

                // MARK: - Registered Guardians Section
                Section(header: Text("Registered Guardians")) {
                    if service.isLoading {
                        ProgressView()
                    } else if service.guardians.isEmpty {
                        Text("No guardians assigned yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(service.guardians) { guardian in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(guardian.guardian_name)
                                        .font(.headline)
                                    Text(guardian.guardian_phone)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let guardian = service.guardians[index]
                                if let id = guardian.id {
                                    service.deleteGuardian(id: id, userId: currentUserId) { _ in }
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(action: {
                        showingAddGuardianAlert = true
                    }) {
                        Label("Add Guardian Manually", systemImage: "person.badge.plus")
                    }
                }
            }
            .navigationTitle("Guardian Settings")
            .onAppear {
                service.fetchGuardians(userId: currentUserId)
            }
            .sheet(isPresented: $showChangeGuardianCodeSheet) {
                ChangeGuardianCodeView(userId: currentUserId)
            }
            .alert("Add Guardian", isPresented: $showingAddGuardianAlert) {
                TextField("Guardian Name", text: $newGuardianName)
                TextField("Phone Number", text: $newGuardianPhone)
                    .keyboardType(.phonePad)
                Button("Save") {
                    if !newGuardianName.isEmpty && !newGuardianPhone.isEmpty {
                        service.addGuardian(userId: currentUserId, name: newGuardianName, phone: newGuardianPhone) { success in
                            if success {
                                newGuardianName = ""
                                newGuardianPhone = ""
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter the name and phone number of the guardian.")
            }
        }
    }
    
    // MARK: - Sync Action Handler
    private func syncAllPhoneContacts() {
        isSyncingContacts = true
        
        ContactSyncManager.syncDeviceContacts(userId: currentUserId) { success, message in
            isSyncingContacts = false
            if success {
                hasSyncedPhoneContacts = true // Permanently locks the button
                print(message)
            } else {
                print("Sync error: \(message)")
            }
        }
    }
}

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
        NavigationView {
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

        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/user/update-pin") else {
            isLoading = false
            errorMessage = "Invalid server URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "currentPin": currentCode.trimmingCharacters(in: .whitespaces),
            "newPin": newCode.trimmingCharacters(in: .whitespaces)
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

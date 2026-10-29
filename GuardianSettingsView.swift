import Foundation
import SwiftUI

// MARK: - Guardian Settings View
struct GuardianSettingsView: View {
    let currentUserId: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = GuardianService()

    @State private var showingAddGuardianAlert = false
    @State private var newGuardianName = ""
    @State private var newGuardianPhone = ""
    
    // Guardian Protection Shield Toggle State
    @State private var isGuardianShieldActive: Bool = true
    
    // Sheet presentation state for Guardian Code update
    @State private var showChangeGuardianCodeSheet = false
    
    // Authorization PIN Alert State for Report Sending
    @State private var showPinForReportAlert = false
    @State private var pinForReportInput = ""
    @State private var isSendingReport = false
    @State private var reportStatusMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        protectionCard
                        guardiansCard
                        reportsCard
                        securityCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Guardian Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        service.fetchGuardians(userId: currentUserId)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
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
            .alert("Authorize Report Dispatch", isPresented: $showPinForReportAlert) {
                SecureField("Enter Guardian Code", text: $pinForReportInput)
                    .keyboardType(.numberPad)
                Button("Send Report") {
                    sendCallLogsReport(pin: pinForReportInput)
                    pinForReportInput = ""
                }
                Button("Cancel", role: .cancel) {
                    pinForReportInput = ""
                }
            } message: {
                Text("Enter your Guardian Code to email recent call history and voicemails to registered guardians.")
            }
        }
    }

    // MARK: - Subviews (Broken down for type-checker efficiency)
    
    private var protectionCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isGuardianShieldActive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "shield.fill")
                        .foregroundColor(isGuardianShieldActive ? .green : .red)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Guardian Protection")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Text(isGuardianShieldActive ? "Scam call screening active" : "Screening currently paused")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $isGuardianShieldActive)
                    .labelsHidden()
                    .tint(.green)
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var guardiansCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Assigned Guardians (\(service.guardians.count))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    showingAddGuardianAlert = true
                }) {
                    Label("Add Guardian", systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                }
            }

            if service.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 8)
            } else if service.guardians.isEmpty {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "person.fill")
                            .foregroundColor(.orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Guardians Assigned")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Mark contacts as Guardian in Trusted Contacts")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(service.guardians) { guardian in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "shield.fill")
                                    .foregroundColor(.green)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(guardian.guardian_name)
                                    .font(.system(size: 15, weight: .bold))

                                Text(guardian.guardian_phone)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                if let id = guardian.id {
                                    service.deleteGuardian(id: id, userId: currentUserId) { _ in }
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red.opacity(0.7))
                                    .font(.system(size: 14))
                            }
                        }
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var reportsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guardian Reports")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)

            Text("Dispatch a recent call history summary and voicemail recordings to all registered guardian email addresses.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            if let status = reportStatusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundColor(status.contains("successfully") ? .green : .red)
            }

            Button(action: {
                showPinForReportAlert = true
            }) {
                HStack {
                    if isSendingReport {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "envelope.fill")
                        Text("Send Call Logs to Guardian(s)")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(service.guardians.isEmpty ? Color(.systemGray4) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(service.guardians.isEmpty || isSendingReport)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guardian Security")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)

            Button(action: {
                showChangeGuardianCodeSheet = true
            }) {
                HStack {
                    Label("Change Guardian Code", systemImage: "key.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Actions
    private func sendCallLogsReport(pin: String) {
        isSendingReport = true
        reportStatusMessage = nil

        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/guardians/send-report") else {
            isSendingReport = false
            reportStatusMessage = "Invalid server URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "userId": currentUserId,
            "guardianPin": pin,
            "reportType": "7days"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isSendingReport = false
                if let error = error {
                    reportStatusMessage = "Error: \(error.localizedDescription)"
                    return
                }

                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    reportStatusMessage = "Report dispatched successfully to guardians!"
                } else {
                    reportStatusMessage = "Failed to dispatch report. Verify Guardian Code."
                }
            }
        }.resume()
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

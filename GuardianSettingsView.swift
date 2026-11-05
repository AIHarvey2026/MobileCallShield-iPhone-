// File Name: GuardianSettingsView.swift

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
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
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

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    service.fetchGuardians(userId: currentUserId)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .bold))
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

    // MARK: - Protection Active Card
    private var protectionCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isGuardianShieldActive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: "shield.fill")
                        .foregroundColor(isGuardianShieldActive ? .green : .red)
                        .font(.system(size: 24, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Guardian Protection")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text(isGuardianShieldActive ? "Scam call screening active" : "Screening currently paused")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $isGuardianShieldActive)
                    .labelsHidden()
                    .tint(.green)
                    .scaleEffect(1.1)
            }
            .padding(18)
        }
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Assigned Guardians List Card
    private var guardiansCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Assigned Guardians (\(service.guardians.count))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    showingAddGuardianAlert = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Add Guardian")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.blue)
                }
            }

            if service.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 12)
            } else if service.guardians.isEmpty {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: "person.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 22, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("No Guardians Assigned")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Mark contacts as Guardian in Trusted Contacts")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
            } else {
                VStack(spacing: 12) {
                    ForEach(service.guardians) { guardian in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 46, height: 46)

                                Image(systemName: "shield.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 20, weight: .bold))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(guardian.guardian_name)
                                    .font(.system(size: 17, weight: .bold))

                                Text(guardian.guardian_phone)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                if let id = guardian.id {
                                    service.deleteGuardian(id: id, userId: currentUserId) { _ in }
                                }
                            }) {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red.opacity(0.85))
                                    .font(.system(size: 18))
                                    .padding(8)
                            }
                        }
                        Divider()
                    }
                }
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

    // MARK: - Guardian Reports Action Card
    private var reportsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Guardian Reports")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.secondary)

            Text("Dispatch recent call history summaries and voicemail recordings to all registered guardian email addresses.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            if let status = reportStatusMessage {
                Text(status)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(status.contains("successfully") ? .green : .red)
            }

            Button(action: {
                showPinForReportAlert = true
            }) {
                HStack(spacing: 8) {
                    if isSendingReport {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Send Call Logs to Guardian(s)")
                            .font(.system(size: 17, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(service.guardians.isEmpty ? Color(.systemGray4) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .disabled(service.guardians.isEmpty || isSendingReport)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Security Settings Card
    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Guardian Security")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.secondary)

            Button(action: {
                showChangeGuardianCodeSheet = true
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "key.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.purple)
                    }

                    Text("Change Guardian Code")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color(.systemGroupedBackground).opacity(0.5))
                .cornerRadius(14)
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

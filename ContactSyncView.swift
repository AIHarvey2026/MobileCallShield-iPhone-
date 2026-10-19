import SwiftUI

// MARK: - Contact Sync View
struct ContactSyncView: View {
    @EnvironmentObject var session: SessionStore
    
    @AppStorage("hasSyncedPhoneContacts") private var hasSyncedPhoneContacts: Bool = false
    @State private var isSyncing: Bool = false
    @State private var statusMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Device Contacts Sync"),
                    footer: Text("Sync your phone's address book with your secure cloud backend to enable instant caller verification.")
                ) {
                    Button(action: {
                        syncContacts()
                    }) {
                        HStack {
                            Image(systemName: hasSyncedPhoneContacts ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                            Text(hasSyncedPhoneContacts ? "Contacts Already Synced" : "Sync Phone Contacts")
                                .fontWeight(.bold)
                            Spacer()
                            if isSyncing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(hasSyncedPhoneContacts || isSyncing)
                    .tint(hasSyncedPhoneContacts ? .gray : .blue)
                }

                if !statusMessage.isEmpty {
                    Section {
                        Text(statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Contact Sync")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func syncContacts() {
        isSyncing = true
        statusMessage = "Syncing contacts..."
        
        ContactSyncManager.syncDeviceContacts(userId: session.userId) { success, message in
            isSyncing = false
            statusMessage = message
            if success {
                hasSyncedPhoneContacts = true
            }
        }
    }
}

#Preview {
    ContactSyncView()
        .environmentObject(SessionStore())
}

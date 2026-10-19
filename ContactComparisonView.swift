import SwiftUI

struct ContactComparisonView: View {
    @StateObject private var syncManager = ContactSyncManager()
    @AppStorage("loggedginUserId") private var userId: Int = 0
    @State private var searchText = ""
    @State private var showingAddContact = false

    // Filtered computed properties for search
    var filteredSyncedContacts: [MCSContactModel] {
        if searchText.isEmpty {
            return syncManager.syncedContacts
        } else {
            return syncManager.syncedContacts.filter {
                $0.name.localizedStandardContains(searchText) || $0.phoneNumber.contains(searchText)
            }
        }
    }

    var filteredUnsyncedContacts: [MCSContactModel] {
        if searchText.isEmpty {
            return syncManager.unsyncedContacts
        } else {
            return syncManager.unsyncedContacts.filter {
                $0.name.localizedStandardContains(searchText) || $0.phoneNumber.contains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search contacts", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                // Action Buttons Header: "Add Single Contact" & "Sync All"
                HStack(spacing: 12) {
                    Button(action: {
                        showingAddContact = true
                    }) {
                        Label("Add Single", systemImage: "person.badge.plus")
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        print("DEBUG: 'Sync All' pressed in UI with userId: \(userId)")
                        syncManager.syncAllContacts(userId: userId)
                    }) {
                        Label("Sync All", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)

                List {
                    Section(header: Text("Protected / Synced Contacts")) {
                        ForEach(filteredSyncedContacts) { contact in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.name).font(.headline)
                                    Text(contact.phoneNumber).font(.subheadline).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("Protected")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(6)
                            }
                        }
                    }

                    Section(header: Text("Unsynced Device Contacts")) {
                        ForEach(filteredUnsyncedContacts) { contact in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.name).font(.headline)
                                    Text(contact.phoneNumber).font(.subheadline).foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    addContactToBackend(contact)
                                }) {
                                    Text("Shield")
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Trusted Contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddContact = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView()
            }
            .onAppear {
                syncManager.fetchDeviceContacts()
                if userId > 0 {
                    syncManager.fetchBackendContacts(userId: userId)
                }
            }
        }
    }

    func addContactToBackend(_ contact: MCSContactModel) {
        print("Shielding contact: \(contact.name)")
    }
}

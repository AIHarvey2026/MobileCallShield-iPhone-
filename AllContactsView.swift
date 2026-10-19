import SwiftUI
import ContactsUI

// MARK: - Sheet Presentation Enum (Only for Contact Picker)
enum ActiveSheet: Identifiable {
    case contactPicker
    
    var id: Int {
        return 1
    }
}

// MARK: - Remote Trusted Contact Model
struct RemoteTrustedContact: Identifiable, Codable {
    let id: Int
    let name: String
    let phoneNumbers: [String]
    var isTrusted: Bool
    var isPrimary: Bool

    // Formats numbers cleanly as (###) ###-####
    var displayPhoneNumber: String {
        let formattedNumbers = phoneNumbers.map { formatPhoneNumber($0) }
        return formattedNumbers.joined(separator: ", ")
    }

    private func formatPhoneNumber(_ number: String) -> String {
        let cleanNumber = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if cleanNumber.count == 10 {
            let area = cleanNumber.prefix(3)
            let prefix = cleanNumber.dropFirst(3).prefix(3)
            let line = cleanNumber.suffix(4)
            return "(\(area)) \(prefix)-\(line)"
        } else if cleanNumber.count == 11 && cleanNumber.hasPrefix("1") {
            let area = cleanNumber.dropFirst(1).prefix(3)
            let prefix = cleanNumber.dropFirst(4).prefix(3)
            let line = cleanNumber.suffix(4)
            return "(\(area)) \(prefix)-\(line)"
        }
        
        return number
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case phoneNumbers = "phone_numbers"
        case isTrusted = "is_guardian"
        case isPrimary = "is_primary"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        phoneNumbers = try container.decodeIfPresent([String].self, forKey: .phoneNumbers) ?? []
        
        isTrusted = try container.decodeIfPresent(Bool.self, forKey: .isTrusted) ?? false
        isPrimary = try container.decodeIfPresent(Bool.self, forKey: .isPrimary) ?? false
    }
}

// MARK: - Trusted Contacts Main View
struct AllContactsView: View {
    @EnvironmentObject var session: SessionStore
    
    @State private var contacts: [RemoteTrustedContact] = []
    @State private var isLoading = false
    @State private var isSyncing = false
    @State private var errorMessage = ""
    
    // Sheet state strictly for the native contact picker
    @State private var activeSheet: ActiveSheet? = nil
    
    @AppStorage("userId") private var currentUserId: Int = 1
    @AppStorage("hasSyncedPhoneContacts") private var hasSyncedPhoneContacts: Bool = false

    // Computed property to maintain alphabetical order by contact name
    var sortedContacts: [RemoteTrustedContact] {
        contacts.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Top Action Buttons Section (Add Single & Sync All)
                Section(header: Text("Actions")) {
                    HStack(spacing: 24) {
                        // 1. Add Single Button
                        Button(action: {
                            activeSheet = .contactPicker
                        }) {
                            Label("Add Single", systemImage: "person.badge.plus")
                                .font(.subheadline)
                        }

                        Spacer()

                        // 2. Sync All Button
                        Button(action: {
                            syncAllPhoneContacts()
                        }) {
                            HStack(spacing: 6) {
                                Label(hasSyncedPhoneContacts ? "Synced" : "Sync All", systemImage: hasSyncedPhoneContacts ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                                    .font(.subheadline)
                                if isSyncing {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isSyncing)
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: Main Section - Trusted Contacts (Alphabetical)
                Section(header: Text("Trusted Contacts")) {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading contacts...")
                            Spacer()
                        }
                    } else if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if sortedContacts.isEmpty {
                        Text("No trusted contacts found.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(sortedContacts) { contact in
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                    Text(contact.displayPhoneNumber.isEmpty ? "No phone number" : contact.displayPhoneNumber)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer(minLength: 4)
                                
                                HStack(spacing: 12) {
                                    // Guardian Toggle
                                    VStack(spacing: 2) {
                                        Text("Guardian")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Toggle("Guardian", isOn: Binding(
                                            get: { contact.isTrusted },
                                            set: { newValue in
                                                if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                                                    contacts[index].isTrusted = newValue
                                                    
                                                    // SAFETY RULE: If Guardian is turned off, Primary must also turn off automatically
                                                    if !newValue && contacts[index].isPrimary {
                                                        contacts[index].isPrimary = false
                                                    }
                                                }
                                                updateGuardianStatus(contactId: contact.id, isGuardian: newValue, userId: session.userId)
                                            }
                                        ))
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                                    }
                                    
                                    // Primary Toggle (With Safety Check)
                                    VStack(spacing: 2) {
                                        Text("Primary")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Toggle("Primary", isOn: Binding(
                                            get: { contact.isPrimary },
                                            set: { newValue in
                                                if newValue {
                                                    // SAFETY RULE: Must be a Guardian first. Auto-enable Guardian if needed.
                                                    if !contact.isTrusted {
                                                        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                                                            contacts[index].isTrusted = true
                                                        }
                                                        updateGuardianStatus(contactId: contact.id, isGuardian: true, userId: session.userId)
                                                    }
                                                    
                                                    // Set this contact as primary and clear others locally
                                                    for index in contacts.indices {
                                                        contacts[index].isPrimary = (contacts[index].id == contact.id)
                                                    }
                                                    updatePrimaryStatus(contactId: contact.id, userId: session.userId)
                                                } else {
                                                    if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                                                        contacts[index].isPrimary = false
                                                    }
                                                }
                                            }
                                        ))
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Trusted Contacts")
            .navigationBarTitleDisplayMode(.inline)
            // PRESENT CONTACT PICKER SHEET
            .sheet(item: $activeSheet) { _ in
                ContactPicker { name, phoneNumber in
                    handleSingleContactSelection(name: name, phoneNumber: phoneNumber)
                }
            }
            .onAppear {
                fetchContacts()
            }
        }
    }

    // MARK: - Isolated Workflow Functions

    private func handleSingleContactSelection(name: String, phoneNumber: String) {
        activeSheet = nil
        uploadTrustedContact(name: name, phoneNumber: phoneNumber, userId: session.userId) { success in
            if success {
                fetchContacts()
            }
        }
    }
    
    private func syncAllPhoneContacts() {
        isSyncing = true
        ContactSyncManager.syncDeviceContacts(userId: session.userId) { success, message in
            isSyncing = false
            if success {
                hasSyncedPhoneContacts = true
                fetchContacts()
            }
        }
    }

    private func fetchContacts() {
        isLoading = true
        errorMessage = ""
        
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/trusted-contacts/\(session.userId)") else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { isLoading = false }
            
            if let error = error {
                DispatchQueue.main.async { errorMessage = "Error: \(error.localizedDescription)" }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { errorMessage = "No data returned." }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([RemoteTrustedContact].self, from: data)
                DispatchQueue.main.async { contacts = decoded }
            } catch {
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let serverError = errorDict["error"] as? String {
                    DispatchQueue.main.async { errorMessage = "Server: \(serverError)" }
                } else {
                    DispatchQueue.main.async { errorMessage = "Failed to parse contacts." }
                }
            }
        }.resume()
    }

    private func updateGuardianStatus(contactId: Int, isGuardian: Bool, userId: Int) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/trusted-contacts/\(contactId)/guardian") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["is_guardian": isGuardian, "userId": userId])
        URLSession.shared.dataTask(with: request).resume()
    }

    private func updatePrimaryStatus(contactId: Int, userId: Int) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/guardians/\(userId)/primary/\(contactId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        URLSession.shared.dataTask(with: request).resume()
    }

    private func uploadTrustedContact(name: String, phoneNumber: String, userId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/trusted-contacts/bulk") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "userId": userId,
            "contacts": [["name": name, "phone_numbers": [phoneNumber], "is_guardian": false]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(statusCode == 200 || statusCode == 201)
            }
        }.resume()
    }
}

// MARK: - Native Contact Picker Wrapper
struct ContactPicker: UIViewControllerRepresentable {
    var onContactSelected: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        init(_ parent: ContactPicker) { self.parent = parent }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
            parent.onContactSelected(name, phone)
            parent.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}

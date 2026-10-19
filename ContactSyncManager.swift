import Foundation
import Contacts
import Combine

class ContactSyncManager: ObservableObject {
    @Published var syncedContacts: [MCSContactModel] = []
    @Published var unsyncedContacts: [MCSContactModel] = []
    
    // MARK: - Fetch Local Device Contacts & Compare with Backend
    func fetchDeviceContacts() {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            guard granted, let self = self else { return }
            
            let keysToFetch = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactPhoneNumbersKey
            ] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            var allDeviceContacts: [MCSContactModel] = []
            
            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                    let contactName = fullName.isEmpty ? "Unknown Contact" : fullName
                    
                    for phoneNumberObj in contact.phoneNumbers {
                        let rawNumber = phoneNumberObj.value.stringValue
                        let normalizedNumber = rawNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                        
                        if !normalizedNumber.isEmpty {
                            let model = MCSContactModel(name: contactName, phoneNumber: normalizedNumber, isTrusted: false, isPrimary: false)
                            if !allDeviceContacts.contains(where: { $0.phoneNumber == normalizedNumber }) {
                                allDeviceContacts.append(model)
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.unsyncedContacts = allDeviceContacts
                }
            } catch {
                print("[ERROR] Failed to fetch local device contacts: \(error)")
            }
        }
    }
    
    // MARK: - Fetch Backend Contacts for Comparison
    func fetchBackendContacts(userId: Int) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/trusted-contacts/\(userId)") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("[ERROR] Network error: \(String(describing: error))")
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("[DEBUG] Status code: \(httpResponse.statusCode)")
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("[ERROR] Server returned error payload: \(errorString)")
                    }
                    return
                }
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Backend raw response: \(jsonString)")
            }
            
            struct BackendContact: Codable {
                let name: String
                let phone_number: String
                let is_guardian: Bool?
                let is_primary: Bool?
            }
            
            do {
                let backendList = try JSONDecoder().decode([BackendContact].self, from: data)
                let backendNumbers = Set(backendList.map { $0.phone_number })
                
                DispatchQueue.main.async {
                    var synced: [MCSContactModel] = []
                    var unsynced: [MCSContactModel] = []
                    
                    let combinedCurrent = self.unsyncedContacts + self.syncedContacts
                    
                    for contact in combinedCurrent {
                        let isBackendMatch = backendNumbers.contains(contact.phoneNumber)
                        if isBackendMatch {
                            let matchInfo = backendList.first(where: { $0.phone_number == contact.phoneNumber })
                            let updated = MCSContactModel(
                                name: contact.name,
                                phoneNumber: contact.phoneNumber,
                                isTrusted: matchInfo?.is_guardian ?? true,
                                isPrimary: matchInfo?.is_primary ?? false
                            )
                            synced.append(updated)
                        } else {
                            unsynced.append(contact)
                        }
                    }
                    
                    if combinedCurrent.isEmpty {
                        for bc in backendList {
                            synced.append(MCSContactModel(
                                name: bc.name,
                                phoneNumber: bc.phone_number,
                                isTrusted: bc.is_guardian ?? true,
                                isPrimary: bc.is_primary ?? false
                            ))
                        }
                    }
                    
                    self.syncedContacts = synced
                    self.unsyncedContacts = unsynced
                }
            } catch {
                print("[ERROR] Failed to parse contact list: \(error)")
            }
        }.resume()
    }
    
    /// Requests access to device contacts, fetches them, and uploads them to the backend in bulk.
    static func syncDeviceContacts(userId: Int, completion: @escaping (Bool, String) -> Void) {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else {
                DispatchQueue.main.async {
                    completion(false, "Permission to access contacts was denied.")
                }
                return
            }
            
            let keysToFetch = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactPhoneNumbersKey
            ] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            var formattedContacts: [[String: Any]] = []
            
            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                    let contactName = fullName.isEmpty ? "Unknown Contact" : fullName
                    
                    var phoneNumbers: [String] = []
                    for phoneNumberObj in contact.phoneNumbers {
                        let rawNumber = phoneNumberObj.value.stringValue
                        let normalizedNumber = rawNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                        
                        if !normalizedNumber.isEmpty && !phoneNumbers.contains(normalizedNumber) {
                            phoneNumbers.append(normalizedNumber)
                        }
                    }
                    
                    if !phoneNumbers.isEmpty {
                        let contactDict: [String: Any] = [
                            "name": contactName,
                            "phone_numbers": phoneNumbers,
                            "is_guardian": false
                        ]
                        formattedContacts.append(contactDict)
                    }
                }
                
                sendBulkContactsToServer(userId: userId, contacts: formattedContacts, completion: completion)
                
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Failed to fetch device contacts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private static func sendBulkContactsToServer(userId: Int, contacts: [[String: Any]], completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/trusted-contacts/bulk") else {
            DispatchQueue.main.async { completion(false, "Invalid server URL.") }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "userId": userId,
            "contacts": contacts
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            DispatchQueue.main.async { completion(false, "Failed to encode contacts payload.") }
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    completion(false, "Server rejected the bulk sync request.")
                    return
                }
                
                completion(true, "Contacts synced successfully!")
            }
        }.resume()
    }
    
    func syncAllContacts(userId: Int) {
        print("DEBUG: 'Sync All' button pressed. Requesting contact access...")
        
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG ERROR: Permission request returned error: \(error.localizedDescription)")
                return
            }
            
            guard granted else {
                print("DEBUG WARNING: User denied contacts permission.")
                return
            }
            
            print("DEBUG: Permission granted. Starting contact fetch...")
            
            let keysToFetch = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactPhoneNumbersKey
            ] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            var formattedContacts: [[String: Any]] = []
            
            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                    let contactName = fullName.isEmpty ? "Unknown Contact" : fullName
                    
                    var phoneNumbers: [String] = []
                    for phoneNumberObj in contact.phoneNumbers {
                        let rawNumber = phoneNumberObj.value.stringValue
                        let normalizedNumber = rawNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                        
                        if !normalizedNumber.isEmpty && !phoneNumbers.contains(normalizedNumber) {
                            phoneNumbers.append(normalizedNumber)
                        }
                    }
                    
                    if !phoneNumbers.isEmpty {
                        let contactDict: [String: Any] = [
                            "name": contactName,
                            "phone_numbers": phoneNumbers,
                            "is_guardian": false
                        ]
                        formattedContacts.append(contactDict)
                    }
                }
                
                print("DEBUG: Fetched \(formattedContacts.count) contacts. Uploading to server...")
                
                ContactSyncManager.sendBulkContactsToServer(userId: userId, contacts: formattedContacts) { success, message in
                    print("DEBUG: Bulk upload response - Success: \(success), Message: \(message)")
                    if success {
                        self.fetchDeviceContacts()
                        self.fetchBackendContacts(userId: userId)
                    }
                }
                
            } catch {
                print("DEBUG CRITICAL ERROR: Failed to fetch contacts: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Save Single Contact
    func saveSingleContact(userId: Int, name: String, phoneNumber: String, completion: (() -> Void)? = nil) {
        guard userId > 0 else {
            print("ERROR: Invalid userId")
            return
        }
        
        let payload: [String: Any] = [
            "userId": userId,
            "contacts": [
                [
                    "name": name,
                    "phone_numbers": [phoneNumber],
                ]
            ]
        ]
        
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/trusted-contacts/bulk") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("ERROR: Failed to encode single contact payload")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("ERROR: Failed to save single contact: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self?.fetchBackendContacts(userId: userId)
                completion?()
            }
        }.resume()
    }
}

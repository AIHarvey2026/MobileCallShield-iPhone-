
import SwiftUI
import Contacts
import ContactsUI

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userId") private var currentUserId: Int = 1
    
    @State private var contactName: String = ""
    @State private var phoneNumber: String = ""
    @State private var showContactPicker: Bool = false
    
    @State private var isSaving: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showingAddContact = false

    var body: some View {
        Form {
            Section(header: Text("Contact Information")) {
                TextField("Contact Name", text: $contactName)
                TextField("Phone Number", text: $phoneNumber)
                    #if os(iOS) || os(tvOS) || os(visionOS)
                    .keyboardType(.phonePad)
                    #endif
                 
                Button(action: {
                    showContactPicker = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.rectangle.stack.fill")
                            .foregroundColor(.blue)
                        Text("Import from Phone Contacts")
                            .foregroundColor(.blue)
                    }
                }
            }
             
            Section {
                Button(action: {
                    saveContact()
                }) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Trusted Contact")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(contactName.isEmpty || phoneNumber.isEmpty || isSaving)
            }
        }
        .navigationTitle("Add Trusted Contact")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showContactPicker) {
            SystemContactPicker { selectedList in
                guard let contact = selectedList.first else { return }
                self.contactName = contact.name
                self.phoneNumber = contact.phoneNumber
            } onError: { errorMessage in
                print("❌ Contact picker error: \(errorMessage)")
            }
        }
        .alert("Status", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func saveContact() {
        isSaving = true
        
        // Using your bulk endpoint to save the single contact reliably
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/trusted-contacts/bulk") else {
            isSaving = false
            alertMessage = "Invalid backend URL."
            showAlert = true
            return
        }
         
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         
        let body: [String: Any] = [
            "userId": currentUserId,
            "contacts": [
                [
                    "name": contactName,
                    "phone_number": phoneNumber,
                    "is_guardian": false
                ]
            ]
        ]
        
        print("[DEBUG] Sending contacts to URL: \(url)")
        print("[DEBUG] Payload userId: \(currentUserId)")
         
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            isSaving = false
            alertMessage = "Failed to serialize contact data."
            showAlert = true
            return
        }
         
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSaving = false
                if let error = error {
                    alertMessage = "Failed to save contact to backend: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    alertMessage = "Contact added successfully!"
                } else {
                    alertMessage = "Server returned an error saving the contact."
                }
                showAlert = true
            }
        }.resume()
    }
}

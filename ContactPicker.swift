import SwiftUI
import ContactsUI

struct SystemContactPicker: UIViewControllerRepresentable {
    var onContactsSelected: ([MCSContactModel]) -> Void
    var onError: (String) -> Void = { _ in }
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {
        // No update needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: SystemContactPicker
        
        init(parent: SystemContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            print("[DEBUG] contactPicker delegate fired! Selected count: \(contacts.count)")
            
            let models = contacts.compactMap { cnContact -> MCSContactModel? in
                let name = "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespaces)
                guard let phone = cnContact.phoneNumbers.first?.value.stringValue else {
                    print("[DEBUG] Skipped contact due to missing phone number.")
                    return nil
                }
                
                print("[DEBUG] Mapped contact: \(name), phone: \(phone)")
                return MCSContactModel(
                    name: name,
                    phoneNumber: phone,
                    isTrusted: true,
                    isPrimary: false
                )
            }
            
            print("[DEBUG] Passing \(models.count) models to parent.onContactsSelected")
            parent.onContactsSelected(models)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            print("[DEBUG] contactPickerDidCancel was called.")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

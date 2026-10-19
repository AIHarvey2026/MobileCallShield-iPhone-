

import SwiftUI
import Contacts
import ContactsUI

struct ContactPickerPresenter: View {
    var onContactsSelected: ([MCSContactModel]) -> Void
    var onCancel: () -> Void

    var body: some View {
        SystemContactPicker { selectedList in
            onContactsSelected(selectedList)
        } onError: { errorMessage in
            print("❌ Picker error: \(errorMessage)")
        }
    }
}

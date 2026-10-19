import SwiftUI
import MapKit
import Combine

// MARK: - Address Autocomplete Search Manager
@MainActor
class AddressSearchManager: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [MKMapItem] = []
    
    private var searchCancellable: AnyCancellable?
    
    init() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
    }
    
    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.count > 2 else {
            self.searchResults = []
            return
        }
         
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.resultTypes = .address
         
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else { return }
            Task { @MainActor in
                self.searchResults = Array(response.mapItems.prefix(4))
            }
        }
    }
}

// MARK: - RegisterView Component
struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    
    // Address fields
    @State private var streetAddress: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var country: String = "United States"
    
    @StateObject private var searchManager = AddressSearchManager()
    @State private var showAddressSuggestions: Bool = true
    
    // Security fields
    @State private var pin: String = ""      // Owner PIN
    @State private var passcode: String = "" // Call screening passphrase
    @State private var agreedToPolicy: Bool = false
    
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var successMessage: String = ""

    // FORM VALIDATION: Properly placed at the struct scope level
    private var isFormValid: Bool {
        !name.isEmpty &&
        !phoneNumber.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !streetAddress.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zipCode.isEmpty &&
        !pin.isEmpty &&
        !passcode.isEmpty &&
        agreedToPolicy
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Account Details
                Section(header: Text("Account Details"), footer: Text("Fields marked with an asterisk (*) are required.")) {
                    HStack {
                        Text("Full Name")
                        Text("*").foregroundColor(.red)
                        Spacer()
                        TextField("Full Name / Username", text: $name)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Text("Phone Number")
                        Text("*").foregroundColor(.red)
                        Spacer()
                        TextField("555-123-4567", text: $phoneNumber)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.phonePad)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Text("Email")
                        Text("*").foregroundColor(.red)
                        Spacer()
                        TextField("Email Address", text: $email)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Text("Password")
                        Text("*").foregroundColor(.red)
                        Spacer()
                        SecureField("Password", text: $password)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                    }
                }
                 
                // MARK: - Address Section with Working Autocomplete
                Section(header: Text("Billing / Home Address")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Street Address")
                            Text("*").foregroundColor(.red)
                            Spacer()
                            TextField("Street Address", text: $streetAddress)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: streetAddress) { newValue in
                                    showAddressSuggestions = true
                                    searchManager.searchQuery = newValue
                                }
                        }
                       
                        if showAddressSuggestions && !searchManager.searchResults.isEmpty && streetAddress.count > 2 {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Suggested Addresses:")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                 
                                ForEach(searchManager.searchResults, id: \.self) { item in
                                    Button(action: {
                                        selectPlacemark(item.placemark)
                                    }) {
                                        HStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.blue)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name ?? "")
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                Text("\(item.placemark.locality ?? ""), \(item.placemark.administrativeArea ?? "") \(item.placemark.postalCode ?? "")")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    Divider()
                                }
                            }
                            .padding(8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                    }
                     
                    HStack {
                        Text("City")
                        Text("*").foregroundColor(.red)
                        Spacer()
                        TextField("City", text: $city)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("State")
                        Text("*").foregroundColor(.red)
                        Spacer()
                        TextField("State / Province", text: $state)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Zip Code")
                        Text("*").foregroundColor(.red)
                        Spacer()
                        TextField("Zip Code", text: $zipCode)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Text("Country")
                        Spacer()
                        TextField("Country", text: $country)
                            .multilineTextAlignment(.trailing)
                    }
                }
                 
                // MARK: - Security & Call Screening
                Section(
                    header: Text("Security & Call Screening"),
                    footer: Text("The Owner PIN protects your account settings. The Voice Passcode is spoken by callers to bypass screening. Guardian PIN defaults to 1234 and can be customized in settings.")
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Owner PIN")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("*").foregroundColor(.red).font(.caption)
                        }
                        SecureField("Enter 4-digit PIN (e.g. 1234)", text: $pin)
                            .keyboardType(.numberPad)
                    }
                    .padding(.vertical, 2)
                     
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Call Screening Voice Passcode")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("*").foregroundColor(.red).font(.caption)
                        }
                        TextField("Enter Voice Passcode (e.g. apple or 1234)", text: $passcode)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.vertical, 2)
                }
                 
                // MARK: - Privacy Policy Agreement Section
                Section(header: Text("Privacy & Legal")) {
                    Toggle(isOn: $agreedToPolicy) {
                        HStack(spacing: 4) {
                            Text("I agree to the")
                            Link("Privacy Policy", destination: URL(string: "https://mobilecallshield.com/privacy")!)
                                .foregroundColor(.blue)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
                 
                // MARK: - Submit Section
                Section {
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                     
                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .foregroundColor(.green)
                    }
                     
                    Button(action: {
                        performRegistration()
                    }) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Register")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
     
    private func selectPlacemark(_ placemark: CLPlacemark) {
        showAddressSuggestions = false
        searchManager.searchResults = []
         
        if let subThoroughfare = placemark.subThoroughfare, let thoroughfare = placemark.thoroughfare {
            self.streetAddress = "\(subThoroughfare) \(thoroughfare)"
        } else if let name = placemark.name {
            self.streetAddress = name
        }
         
        self.city = placemark.locality ?? ""
        self.state = placemark.administrativeArea ?? ""
        self.zipCode = placemark.postalCode ?? ""
        self.country = placemark.country ?? "United States"
    }

    // MARK: - Helper Methods
    private func standardizeState(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count == 2 {
            return trimmed.uppercased()
        }
         
        let states = [
            "alabama": "AL", "alaska": "AK", "arizona": "AZ", "arkansas": "AR", "california": "CA",
            "colorado": "CO", "connecticut": "CT", "delaware": "DE", "florida": "FL", "georgia": "GA",
            "hawaii": "HI", "idaho": "ID", "illinois": "IL", "indiana": "IN", "iowa": "IA",
            "kansas": "KS", "kentucky": "KY", "louisiana": "LA", "maine": "ME", "maryland": "MD",
            "massachusetts": "MA", "michigan": "MI", "minnesota": "MN", "mississippi": "MS", "missouri": "MO",
            "montana": "MT", "nebraska": "NE", "nevada": "NV", "new hampshire": "NH", "new jersey": "NJ",
            "new mexico": "NM", "new york": "NY", "north carolina": "NC", "north dakota": "ND", "ohio": "OH",
            "oklahoma": "OK", "oregon": "OR", "pennsylvania": "PA", "rhode island": "RI", "south carolina": "SC",
            "south dakota": "SD", "tennessee": "TN", "texas": "TX", "utah": "UT", "vermont": "VT",
            "virginia": "VA", "washington": "WA", "west virginia": "WV", "wisconsin": "WI", "wyoming": "WY"
        ]
         
        return states[trimmed.lowercased()] ?? trimmed.uppercased()
    }

    private func performRegistration() {
        isLoading = true
        errorMessage = ""
        successMessage = ""

        var formattedPhone = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if formattedPhone.count == 10 {
            formattedPhone = "+1" + formattedPhone
        } else if !formattedPhone.hasPrefix("+") {
            formattedPhone = "+" + formattedPhone
        }

        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/auth/register") else {
            isLoading = false
            errorMessage = "Invalid server URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "phoneNumber": formattedPhone,
            "email": email.trimmingCharacters(in: .whitespaces),
            "password": password,
            "streetAddress": streetAddress.trimmingCharacters(in: .whitespaces),
            "city": city.trimmingCharacters(in: .whitespaces),
            "state": standardizeState(state),
            "zipCode": zipCode.trimmingCharacters(in: .whitespaces),
            "country": country.trimmingCharacters(in: .whitespaces),
            "pin": pin.trimmingCharacters(in: .whitespaces),
            "passcode": passcode.trimmingCharacters(in: .whitespaces)
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
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
                        let successFlag = json["success"] as? Bool ?? false
                        if successFlag {
                            successMessage = "Account created successfully! You can now log in."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        } else {
                            errorMessage = json["error"] as? String ?? "Registration failed."
                        }
                    }
                } catch {
                    errorMessage = "Failed to parse server response."
                }
            }
        }.resume()
    }
}

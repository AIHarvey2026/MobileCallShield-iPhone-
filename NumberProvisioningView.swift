import SwiftUI

struct NumberProvisioningView: View {
    @AppStorage("loggedInUserId") private var loggedInUserId: Int = 1
    @State private var areaCodeInput: String = ""
    @State private var assignedNumber: String?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        Form {
            Section(
                header: Text("Claim Your Screening Number"),
                footer: Text("Enter your local 3-digit area code to automatically provision your dedicated SeniorScamShield phone number.")
            ) {
                TextField("Area Code (e.g., 512)", text: $areaCodeInput)
                    .keyboardType(.numberPad)
                
                Button(action: provisionNumber) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Get My Number")
                            .fontWeight(.bold)
                    }
                }
                .disabled(areaCodeInput.count < 3 || isLoading)
            }

            if let number = assignedNumber {
                Section(header: Text("Your Dedicated Number")) {
                    Text(number)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                    Text("You can now set up call forwarding from your carrier to this number.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error).foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Phone Setup")
    }

    private func provisionNumber() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/subscription/activate") else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": loggedInUserId,
            "areaCode": areaCodeInput
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let data = data, let httpRes = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response from server."
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool, success {
                        self.assignedNumber = json["assignedPhoneNumber"] as? String
                        successMessage = "Phone number successfully assigned!"
                    } else {
                        let errStr = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                        errorMessage = errStr ?? "Failed to provision number."
                    }
                } catch {
                    errorMessage = "Failed to decode server response."
                }
            }
        }.resume()
    }
}

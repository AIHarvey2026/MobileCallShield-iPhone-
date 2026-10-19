
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct SubscribeView: View {
    @AppStorage("loggedInUserId") private var loggedInUserId: Int = 1
    @State private var areaCodeInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var stripeURL: URL? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header Illustration & Title
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 90, height: 90)

                                Image(systemName: "shield.fill")
                                    .font(.system(size: 42))
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 10)

                            Text("Protect Your Line")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Enter your local area code to activate your 24/7 automated scam shielding and secure phone routing.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }

                        // Form Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Local Area Code")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextField("e.g. 512", text: $areaCodeInput)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            Button(action: startCheckout) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Continue to Secure Checkout")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(areaCodeInput.count == 3 ? Color.blue : Color.gray.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(areaCodeInput.count != 3 || isLoading)
                            .padding(.top, 4)
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: Binding(
                get: { stripeURL.map { IdentifiableURL(url: $0) } },
                set: { stripeURL = $0?.url }
            )) { item in
                SafariView(url: item.url)
            }
        }
    }

    private func startCheckout() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/create-checkout-session") else {
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

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let urlString = json["url"] as? String,
                      let checkoutUrl = URL(string: urlString) else {
                    errorMessage = "Failed to start checkout session."
                    return
                }

                self.stripeURL = checkoutUrl
            }
        }.resume()
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

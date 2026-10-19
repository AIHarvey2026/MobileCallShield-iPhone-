import SwiftUI

struct AdminDashboardView: View {
    @State private var users: [AdminUser] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Connecting to server...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("(Render free instance may take ~30s to wake up)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
            } else if let errorMessage = errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connection Failed")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        fetchAdminData()
                    }
                    .padding(.top, 8)
                }
            } else {
                ForEach(users) { user in
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.headline)
                        Text(user.phoneNumber)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Admin Panel")
        .onAppear {
            fetchAdminData()
        }
    }

    private func fetchAdminData() {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/admin/users") else {
            isLoading = false
            return
        }
        
        print("[DEBUG] Sending contacts to URL: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60.0 // Allow up to 60s for Render container wake-up

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("[ADMIN ERROR]: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    self.errorMessage = "Server returned an invalid response."
                    return
                }

                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }

                do {
                    self.users = try JSONDecoder().decode([AdminUser].self, from: data)
                } catch {
                    self.errorMessage = "Failed to parse admin data."
                    print("[DECODE ERROR]: \(error)")
                }
            }
        }.resume()
    }
}

struct AdminUser: Identifiable, Codable {
    let id: Int
    let name: String
    let phoneNumber: String
}

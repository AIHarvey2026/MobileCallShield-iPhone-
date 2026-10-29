import SwiftUI

struct AdminUser: Identifiable, Codable {
    let id: Int
    let name: String
    let email: String
    let phoneNumber: String?
    let isAdmin: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case phoneNumber = "phone_number"
        case isAdmin = "is_admin"
    }
}

struct AdminDashboardView: View {
    var onBackClick: () -> Void = {}

    @State private var userList: [AdminUser] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack {
                if isLoading {
                    ProgressView()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if userList.isEmpty {
                    Text("No users found.")
                        .foregroundColor(.secondary)
                } else {
                    List(userList) { user in
                        AdminUserCard(user: user)
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("Admin Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBackClick) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            fetchAdminUsers()
        }
    }

    private func fetchAdminUsers() {
            isLoading = true
            errorMessage = nil

            // DEBUG: Print all keys in UserDefaults to find the exact token key name
            let allDefaults = UserDefaults.standard.dictionaryRepresentation()
            print("[DEBUG] All UserDefaults keys present: \(allDefaults.keys)")

            guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/admin/users") else {
                errorMessage = "Invalid URL."
                isLoading = false
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 60.0

            // Try checking multiple common keys just in case
            let token = UserDefaults.standard.string(forKey: "token")
                     ?? UserDefaults.standard.string(forKey: "authToken")
                     ?? UserDefaults.standard.string(forKey: "jwtToken")

            if let token = token, !token.isEmpty {
                print("[DEBUG] Found valid token starting with: \(token.prefix(10))...")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                print("[DEBUG ERROR] No token found under 'token', 'authToken', or 'jwtToken'!")
            }
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false

                    if let error = error {
                        errorMessage = "Network error: \(error.localizedDescription)"
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        errorMessage = "Invalid server response."
                        return
                    }

                    print("[DEBUG] Admin response status code: \(httpResponse.statusCode)")

                    guard httpResponse.statusCode == 200 else {
                        if let data = data, let bodyString = String(data: data, encoding: .utf8) {
                            print("[ADMIN ERROR BODY]: \(bodyString)")
                        }
                        errorMessage = "Access denied or server error (\(httpResponse.statusCode))"
                        return
                    }

                    guard let data = data else {
                        errorMessage = "No data received."
                        return
                    }

                    do {
                        let decoder = JSONDecoder()
                        userList = try decoder.decode([AdminUser].self, from: data)
                    } catch {
                        errorMessage = "Failed to parse user data."
                        print("[DECODE ERROR]: \(error)")
                    }
                }
            }.resume()
        }
}

struct AdminUserCard: View {
    let user: AdminUser

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(user.isAdmin ? Color.blue.opacity(0.15) : Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: user.isAdmin ? "shield.fill" : "person.fill")
                    .foregroundColor(user.isAdmin ? .blue : .secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if user.isAdmin {
                        Text("ADMIN")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let phone = user.phoneNumber, !phone.isEmpty {
                    Text(phone)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

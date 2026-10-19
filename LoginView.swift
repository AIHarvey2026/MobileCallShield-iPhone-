import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionStore

    @AppStorage("loggedInUserId") private var loggedInUserId: Int = 0
    @AppStorage("userRole") private var userRole: String = "user"
    @AppStorage("isAdmin") private var isAdmin: Bool = false
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showingForgotPassword = false
    @State private var resetEmail = ""
    @State private var showingRegisterSheet = false
    
    @State private var logoUrlString: String = ""
    @State private var appTitle: String = "Mobile Call Shield"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                 
                VStack(spacing: 24) {
                    Spacer()
                     
                    // Dynamic Logo Header
                    ZStack {
                        if let url = URL(string: logoUrlString), !logoUrlString.isEmpty {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 190, height: 150)
                                        .clipShape(Circle())
                                case .failure(_):
                                    Image("MCS - Phone Icon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 190, height: 150)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image("MCS - Phone Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                        }
                    }
                    .frame(height: 140)
                     
                    Text(appTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                     
                    Text("Sign in to protect your device")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                     
                    Spacer()
                     
                    // Input Fields Card
                    VStack(spacing: 16) {
                        TextField("User Name (Email)", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                         
                        // Password Field
                        HStack {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("Password", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                             
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                         
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                         
                        Button(action: {
                            performLogin()
                        }) {
                            HStack {
                                Spacer()
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Log In")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .disabled(username.isEmpty || password.isEmpty || isLoading)
                         
                        // Forgot Password Button
                        Button(action: {
                            showingForgotPassword = true
                        }) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                        .alert("Reset Password", isPresented: $showingForgotPassword) {
                            TextField("Enter your email", text: $resetEmail)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                             
                            Button("Send Reset Link") {
                                sendPasswordResetRequest()
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("Enter the email address associated with your account.")
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Create Account Link
                        HStack {
                            Text("Don't have an account?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                             
                            Button(action: {
                                showingRegisterSheet = true
                            }) {
                                Text("Create Account")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .sheet(isPresented: $showingRegisterSheet) {
                            RegisterView()
                        }
                    }
                    .padding(.horizontal, 24)
                     
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                fetchAppSettings()
            }
        }
    }

    private func fetchAppSettings() {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/settings") else { return }
         
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
             
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let settings = json["settings"] as? [String: Any] {
                    DispatchQueue.main.async {
                        if let fetchedLogo = settings["logo_url"] as? String {
                            self.logoUrlString = fetchedLogo
                        }
                        if let fetchedName = settings["app_name"] as? String {
                            self.appTitle = fetchedName
                        }
                    }
                }
            } catch {
                print("Failed to decode settings: \(error)")
            }
        }.resume()
    }

    private func performLogin() {
        isLoading = true
        errorMessage = ""
         
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/auth/login") else {
            isLoading = false
            errorMessage = "Invalid server URL."
            return
        }
         
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         
        let body: [String: Any] = [
            "email": username.trimmingCharacters(in: .whitespaces),
            "password": password
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
                            let resolvedUserId: Int
                            if let userDict = json["user"] as? [String: Any],
                               let userId = userDict["id"] as? Int {
                                resolvedUserId = userId
                                userRole = (userDict["role"] as? String) ?? "user"
                                isAdmin = userRole.lowercased() == "admin"
                            } else {
                                resolvedUserId = 1
                            }
                            
                            // Save to legacy AppStorage keys if needed
                            loggedInUserId = resolvedUserId
                            
                            // UPDATE SESSION STORE: This instantly updates the global session & triggers prints!
                            session.login(userId: resolvedUserId)
                            print("[DEBUG - LoginView] Successfully logged in and assigned userId: \(resolvedUserId)")
                            
                        } else {
                            let serverError = json["error"] as? String ?? "Unknown server rejection."
                            errorMessage = serverError
                        }
                    } else {
                        errorMessage = "Invalid response format from server."
                    }
                } catch {
                    errorMessage = "Failed to parse response."
                }
            }
        }.resume()
    }

    private func sendPasswordResetRequest() {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/forgot-password") else { return }
         
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         
        let body = ["email": resetEmail.trimmingCharacters(in: .whitespaces)]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
         
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                errorMessage = "If that email exists, reset instructions have been sent."
            }
        }.resume()
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionStore())
}

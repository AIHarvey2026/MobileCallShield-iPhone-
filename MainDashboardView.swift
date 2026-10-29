import SwiftUI

struct MainDashboardView: View {
    @Binding var isLoggedIn: Bool
    
    @AppStorage("userRole") private var userRole: String = "user"
    @AppStorage("isAdmin") private var isAdmin: Bool = false
    @AppStorage("loggedInUserId") private var loggedInUserId: Int = 1
    
    @State private var showLogoutAlert: Bool = false
    @State private var isPulsing: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                 
                ScrollView {
                    VStack(spacing: 20) {
                        // Pulsing Active Protection Shield Logo
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .scaleEffect(isPulsing ? 1.3 : 1.0)
                                .opacity(isPulsing ? 0.2 : 0.8)
                             
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 95, height: 95)
                             
                            Image(systemName: "shield.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.green)
                             
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(height: 150)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                isPulsing = true
                            }
                        }
                         
                        Text("Protection Active")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                         
                        Text("Your device is actively guarding against scam calls.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                         
                        // Main Navigation Cards / Buttons
                        VStack(spacing: 16) {
                            // Guardian & Security Settings
                            NavigationLink(destination: GuardianSettingsView(currentUserId: loggedInUserId)) {
                                DashboardCard(icon: "shield.fill", iconColor: .purple, title: "Guardian & Security Settings")
                            }
                            
                            // Manage Trusted Contacts
                            NavigationLink(destination: AllContactsView()) {
                                DashboardCard(icon: "person.2.fill", iconColor: .blue, title: "Manage Trusted Contacts")
                            }
                             
                            // Call History & Voicemails (Matched to CallHistoryView)
                            NavigationLink(destination: CallHistoryView()) {
                                DashboardCard(icon: "phone.bubble.left.fill", iconColor: .indigo, title: "Call History & Voicemails")
                            }
                            
                            // Shield Settings (Passing currentUserId)
                            // Shield Settings
                        NavigationLink(destination: AppSettingsView()) {
                                DashboardCard(icon: "shield.lefthalf.filled", iconColor: .green, title: "Shield Settings")
                            }

                            // Subscription & Billing
                            NavigationLink(destination: SubscribeView()) {
                                DashboardCard(icon: "creditcard.fill", iconColor: .teal, title: "Subscription & Billing")
                            }
                             
                            // Admin Control Panel (Hidden UNLESS logged-in user is Admin)
                            if isAdmin || userRole.lowercased() == "admin" {
                                NavigationLink(destination: AdminDashboardHubView()) { // <--- Now goes to the Hub!
                                    DashboardCard(icon: "gearshape.2.fill", iconColor: .orange, title: "Administration Settings")
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Log Out of Mobile Call Shield?", isPresented: $showLogoutAlert) {
                Button("OK", role: .destructive) {
                    performLogout()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You are about to log out of the app. You will no longer be protected by Mobile Call Shield until you log back in.")
            }
        }
    }

    private func performLogout() {
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
        }
        isLoggedIn = false
    }
}

struct DashboardCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
            Text(title)
                .font(.system(size: 15, weight: .semibold)) // Adjusted font size here
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

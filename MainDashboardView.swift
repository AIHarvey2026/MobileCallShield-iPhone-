import SwiftUI

struct MainDashboardView: View {
    @Binding var isLoggedIn: Bool
    
    @AppStorage("userRole") private var userRole: String = "user"
    @AppStorage("isAdmin") private var isAdmin: Bool = false
    @AppStorage("loggedInUserId") private var loggedInUserId: Int = 1
    
    @State private var showLogoutAlert: Bool = false
    @State private var isPulsing: Bool = false
    
    // State to present the Screenshot / Document Shield scanner view
    @State private var showScreenshotScanner: Bool = false
    
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
                         
                        // =========================================================
                        // SEPARATED FEATURE SECTIONS WITH SHADED BORDERS & TITLES
                        // =========================================================
                        VStack(spacing: 16) {
                            
                            // SECTION 1: MOBILE CALL SHIELD
                            SectionCard(title: "Mobile Call Shield") {
                                NavigationLink(destination: AppSettingsView()) {
                                    DashboardCard(icon: "shield.lefthalf.filled", iconColor: .green, title: "Shield Settings")
                                }
                            }

                            // SECTION 2: DOCUMENT & SCREENSHOT SHIELD
                            SectionCard(title: "Document & Image Verification") {
                                Button(action: {
                                    showScreenshotScanner = true
                                }) {
                                    DashboardCard(icon: "doc.text.viewfinder", iconColor: .purple, title: "Scan Screenshot / Document")
                                }
                            }

                            // SECTION 3: GUARDIAN PROTECTION & SECURITY
                            SectionCard(title: "Guardian Protection & Security") {
                                NavigationLink(destination: GuardianSettingsView(currentUserId: loggedInUserId)) {
                                    DashboardCard(icon: "shield.fill", iconColor: .purple, title: "Guardian & Security Settings")
                                }
                                
                                NavigationLink(destination: AllContactsView()) {
                                    DashboardCard(icon: "person.2.fill", iconColor: .blue, title: "Manage Trusted Contacts")
                                }
                            }

                            // SECTION 4: CALL HISTORY & ACTIVITY
                            SectionCard(title: "Call History & Activity") {
                                NavigationLink(destination: CallHistoryView()) {
                                    DashboardCard(icon: "phone.bubble.left.fill", iconColor: .indigo, title: "Call History & Voicemails")
                                }
                            }

                            // SECTION 5: ACCOUNT & BILLING
                            SectionCard(title: "Account & Billing") {
                                NavigationLink(destination: SubscribeView()) {
                                    DashboardCard(icon: "creditcard.fill", iconColor: .teal, title: "Subscription & Billing")
                                }
                                
                                // Admin Control Panel (Hidden UNLESS logged-in user is Admin)
                                if isAdmin || userRole.lowercased() == "admin" {
                                    NavigationLink(destination: AdminDashboardHubView()) {
                                        DashboardCard(icon: "gearshape.2.fill", iconColor: .orange, title: "Administration Settings")
                                    }
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
            // Present full DocumentShieldView sheet
            .sheet(isPresented: $showScreenshotScanner) {
                DocumentShieldView(userId: loggedInUserId, userToken: UserDefaults.standard.string(forKey: "token") ?? "")
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

// MARK: - Reusable Section Container Card with Shaded Border
struct SectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            VStack(spacing: 10) {
                content
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Dashboard Row Card Component (Updated for Senior Accessibility)
struct DashboardCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                 
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }
             
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
             
            Spacer()
             
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemGroupedBackground).opacity(0.6))
        .cornerRadius(14)
    }
}

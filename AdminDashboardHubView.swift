import SwiftUI

struct AdminDashboardHubView: View {
    var body: some View {
        List {
            Section(header: Text("Administration Options")) {
                NavigationLink(destination: AdminDashboardView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("User Management")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("View and manage registered accounts & admin roles")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                NavigationLink(destination: AdminFinancialsView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.green)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Financials")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("View subscription revenue and Stripe billing metrics")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Admin Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

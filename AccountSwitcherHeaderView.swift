import SwiftUI

enum AccountRole: String, Codable {
    case personalOwner = "Personal Account"
    case managedSenior = "Managing Senior Profile"
}

struct ManagedSeniorProfile: Identifiable, Codable {
    let seniorId: Int
    let seniorName: String
    let seniorPhone: String
    
    var id: Int { seniorId }
}

struct AccountSwitcherHeaderView: View {
    @EnvironmentObject var session: SessionStore
    @Binding var currentRole: AccountRole
    @Binding var activeDisplayName: String
    let managedSeniors: [ManagedSeniorProfile]
    
    let onSelectPersonal: () -> Void
    let onSelectSenior: (ManagedSeniorProfile) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(currentRole.rawValue)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(activeDisplayName)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Menu {
                Button(action: onSelectPersonal) {
                    Label("My Personal Account", systemImage: "person.fill")
                }
                
                Divider()
                
                if managedSeniors.isEmpty {
                    Text("No managed profiles found")
                        .font(.caption)
                } else {
                    ForEach(managedSeniors) { senior in
                        Button(action: { onSelectSenior(senior) }) {
                            Label("🛡️ \(senior.seniorName) (\(senior.seniorPhone))", systemImage: "shield.fill")
                        }
                    }
                }
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.blue)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

import SwiftUI

struct CarrierActivationView: View {
    let selectedCarrierRaw: String
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedAlert = false
    
    // Assigned Twilio screening number from your backend setup
    let twilioNumber = "+12812476667"
    
    var currentCarrier: MobileCarrier {
        MobileCarrier(rawValue: selectedCarrierRaw) ?? .att
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header Icon
                Image(systemName: "phone.badge.waveform")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                Text("Activate Call Protection")
                    .font(.title2)
                    .bold()
                
                Text("Your account is ready! To start screening calls through your **\(currentCarrier.rawValue)** network, please activate conditional call forwarding.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Code Display Box
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Activation Code:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(currentCarrier.forwardingCode(for: twilioNumber))
                        .font(.system(.title3, design: .monospaced))
                        .bold()
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Button 1: Copy Code
                    Button(action: {
                        let code = currentCarrier.forwardingCode(for: twilioNumber)
                        UIPasteboard.general.string = code
                        showCopiedAlert = true
                    }) {
                        Label("Copy Activation Code", systemImage: "doc.on.doc")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // Button 2: Open Phone App
                    Button(action: {
                        if let url = URL(string: "tel://") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Open Phone App & Dial", systemImage: "phone.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Finish Button
                Button("Done / Skip for Now") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
            .padding()
            .navigationTitle("Setup Wizard")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Code Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Paste this code into your iPhone Phone app keypad and press Call to activate protection.")
            }
        }
    }
}

#Preview {
    CarrierActivationView(selectedCarrierRaw: "AT&T")
}

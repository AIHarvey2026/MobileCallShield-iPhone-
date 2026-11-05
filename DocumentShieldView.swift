import SwiftUI
import PhotosUI

struct DocumentShieldView: View {
    let userId: Int
    let userToken: String
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var textInput: String = ""
    @State private var errorMessage: String = ""
    
    @State private var showCamera: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        actionButtonsCard
                        previewCard
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Document Shield")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("Back")
                                .font(.system(size: 17, weight: .bold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
        }
    }

    // MARK: - Subviews
    private var headerCard: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.blue)
            }

            Text("Scam Verification Hub")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Text("Verify suspicious text messages, emails, photos, or physical documents instantly.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }

    private var actionButtonsCard: some View {
        VStack(spacing: 14) {
            // 1. Accessibility Settings Button (Filled Blue)
            Button(action: { openAccessibilitySettings() }) {
                HStack(spacing: 10) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Enable Floating Scan Button")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.blue)
                .cornerRadius(14)
            }

            // 2. Camera Button (Outlined Blue)
            Button(action: { showCamera = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Take Photo of Document")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .foregroundColor(Color.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue, lineWidth: 1.5)
                )
            }

            // 3. Open Messages / Email App (Outlined Blue)
            Button(action: { openMessagesApp() }) {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Open Text Messages / Email")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .foregroundColor(Color.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue, lineWidth: 1.5)
                )
            }

            // 4. Gallery PhotosPicker (Outlined Blue)
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 20, weight: .bold))
                    Text("Select Screenshot from Gallery")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .foregroundColor(Color.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue, lineWidth: 1.5)
                )
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }

            Spacer(minLength: 4)

            // 5. Text Input Field
            TextField("Or paste suspicious text or email here...", text: $textInput)
                .font(.system(size: 16))
                .padding(16)
                .frame(height: 54)
                .background(Color(.systemGroupedBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var previewCard: some View {
        if let image = selectedImage {
            VStack(spacing: 14) {
                Text("Selected Image Preview")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)
                    .cornerRadius(12)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
            )
        }
    }

    // MARK: - Helper Actions
    private func openAccessibilitySettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func openMessagesApp() {
        if let url = URL(string: "sms:") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                errorMessage = "Could not open messaging app automatically."
            }
        }
    }
}

// MARK: - UIKit Camera Picker Representable
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType = .camera
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

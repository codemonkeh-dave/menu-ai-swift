import SwiftUI
import PhotosUI
import UIKit

struct ContentView: View {
    @State private var image: UIImage?
    @State private var isShowingCamera = false
    @State private var isShowingPhotoLibrary = false
    @State private var showingSourcePicker = false
    @State private var isUploading = false
    @State private var menu: Menu?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            VStack {
                if let menu = menu {
                    MenuView(menu: menu) {
                        self.menu = nil
                    }
                } else {
                    VStack(spacing: 30) {
                        if isUploading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.blue)
                                Text("Analyzing Menu...")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                    .padding(.bottom, 8)
                                
                                Text("AI Menu Scanner")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Capture a menu to identify dishes")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.bottom, 20)

                            VStack(spacing: 16) {
                                Button(action: {
                                    isShowingCamera = true
                                }) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                        Text("Take Photo")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(14)
                                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                .accessibilityLabel("Take Photo")
                                
                                Button(action: {
                                    isShowingPhotoLibrary = true
                                }) {
                                    HStack {
                                        Image(systemName: "photo.fill")
                                        Text("Select from Photos")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(14)
                                }
                                .accessibilityLabel("Select from Photos")
                            }
                            .padding(.horizontal, 30)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingCamera, onDismiss: uploadImage) {
                CameraView(image: $image)
            }
            .photosPicker(isPresented: $isShowingPhotoLibrary, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            image = uiImage
                            selectedPhotoItem = nil // Clear selection to prevent scene errors
                            uploadImage()
                        }
                    }
                }
            }
            .alert(isPresented: $showingError) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }

    func uploadImage() {
        guard let image = image else { return }

        isUploading = true

        Task {
            do {
                let fetchedMenu = try await NetworkManager.shared.uploadImage(image)
                DispatchQueue.main.async {
                    self.menu = fetchedMenu
                    self.isUploading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isUploading = false
                    self.image = nil
                    self.selectedPhotoItem = nil
                }
            }
        }
    }
}

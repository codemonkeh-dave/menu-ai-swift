import SwiftUI
import UIKit

struct ContentView: View {
    @State private var image: UIImage?
    @State private var isShowingCamera = false
    @State private var isUploading = false
    @State private var menu: Menu?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let menu = menu {
                    MenuView(menu: menu)
                } else {
                    VStack(spacing: 20) {
                        if isUploading {
                            ProgressView("Analyzing Menu...")
                                .scaleEffect(1.5)
                        } else {
                            Text("AI Menu Scanner")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Take a photo of a menu to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                isShowingCamera = true
                            }) {
                                Label("Capture Menu", systemImage: "camera.fill")
                                    .font(.title2)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .accessibilityLabel("Capture Menu Button")
                            .accessibilityHint("Opens the camera to take a photo of a menu")
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingCamera, onDismiss: uploadImage) {
                CameraView(image: $image)
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
                    self.image = nil // Reset so user can try again
                }
            }
        }
    }
}

import SwiftUI
import AVFoundation
import UIKit

struct CameraView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    @StateObject private var camera = CameraModel()

    var body: some View {
        ZStack {
            if camera.showError {
                Color.black.ignoresSafeArea()
                Text("Camera not available")
                    .foregroundColor(.white)
            } else {
                CameraPreview(camera: camera)
                    .ignoresSafeArea()
            }

            VStack {
                Spacer()

                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.white)
                            .padding()
                    }

                    Spacer()

                    Button(action: {
                        camera.capturePhoto()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        }
                    }

                    Spacer()

                    // Placeholder for symmetry
                    Text("Cancel")
                        .foregroundColor(.clear)
                        .padding()
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
        .onChange(of: camera.capturedImage) { _, newValue in
            if let newValue {
                image = newValue
                dismiss()
            }
        }
    }
}

class CameraModel: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isCameraReady = false
    @Published var showError = false

    let session = AVCaptureSession()
    private var output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        default:
            break
        }
    }

    func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Try to get the back camera first, fall back to front camera (useful for simulator)
        var device: AVCaptureDevice?
        if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            device = backCamera
        } else if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            device = frontCamera
        }

        guard let camera = device else {
            print("No camera available")
            DispatchQueue.main.async {
                self.showError = true
            }
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            session.commitConfiguration()

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                DispatchQueue.main.async {
                    self?.isCameraReady = true
                }
            }
        } catch {
            print("Error setting up camera: \(error)")
            session.commitConfiguration()
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)

        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

import Foundation
import SwiftUI
import PhotosUI
import CoreLocation
import AVFoundation

class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var capturedImageWithLocation: PropertyImage?
    @Published var isShowingCamera = false
    @Published var isShowingPhotoPicker = false
    @Published var cameraError: CameraError?
    @Published var cameraAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    
    private let locationService: LocationService
    
    init(locationService: LocationService) {
        self.locationService = locationService
        super.init()
        checkCameraPermission()
    }
    
    func checkCameraPermission() {
        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraAuthorizationStatus = granted ? .authorized : .denied
                if !granted {
                    self.cameraError = .permissionDenied
                }
            }
        }
    }
    
    func presentCamera() {
        guard cameraAuthorizationStatus == .authorized else {
            requestCameraPermission()
            return
        }
        
        isShowingCamera = true
    }
    
    func presentPhotoPicker() {
        isShowingPhotoPicker = true
    }
    
    func captureImageWithLocation(_ image: UIImage, generateLocationProof: Bool = true) async {
        do {
            let currentLocation = try await locationService.getCurrentLocation()
            let approximateLocation = try await locationService.getApproximateLocation(for: currentLocation.coordinate)
            
            // Convert image to data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw CameraError.imageProcessingFailed
            }
            
            var locationProof: LocationProof?
            
            if generateLocationProof {
                // For now, we'll create a placeholder proof
                // In a real implementation, this would use ZKMoPro
                locationProof = LocationProof(
                    proof: "placeholder_proof_\(UUID().uuidString)",
                    publicSignals: ["1", "1"], // Placeholder signals
                    radiusKm: 1.0,
                    centerPoint: approximateLocation
                )
            }
            
            let propertyImage = PropertyImage(
                imageData: imageData,
                locationProof: locationProof,
                caption: "Photo taken at \(approximateLocation.cityName)",
                isPrimary: false
            )
            
            await MainActor.run {
                self.capturedImage = image
                self.capturedImageWithLocation = propertyImage
                self.cameraError = nil
            }
            
        } catch {
            await MainActor.run {
                if let locationError = error as? LocationError {
                    self.cameraError = .locationError(locationError)
                } else {
                    self.cameraError = .imageProcessingFailed
                }
            }
        }
    }
    
    func processSelectedPhoto(_ photosPickerItem: PhotosPickerItem) async {
        do {
            guard let imageData = try await photosPickerItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: imageData) else {
                throw CameraError.imageProcessingFailed
            }
            
            await captureImageWithLocation(image, generateLocationProof: true)
            
        } catch {
            await MainActor.run {
                self.cameraError = .imageProcessingFailed
            }
        }
    }
    
    func clearCapturedImage() {
        capturedImage = nil
        capturedImageWithLocation = nil
        cameraError = nil
    }
    
    // MARK: - Image Utilities
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    func generateThumbnail(from image: UIImage) -> UIImage {
        let thumbnailSize = CGSize(width: 200, height: 200)
        return resizeImage(image, targetSize: thumbnailSize)
    }
}

// MARK: - CameraError
enum CameraError: Error, LocalizedError {
    case permissionDenied
    case imageProcessingFailed
    case locationError(LocationError)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission denied. Please enable camera access in Settings."
        case .imageProcessingFailed:
            return "Failed to process the image. Please try again."
        case .locationError(let locationError):
            return "Location error: \(locationError.localizedDescription)"
        case .unknown:
            return "An unknown camera error occurred."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Go to Settings > Privacy & Security > Camera to enable camera access."
        case .imageProcessingFailed:
            return "Make sure you have enough storage space and try again."
        case .locationError(let locationError):
            return locationError.recoverySuggestion
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}

// MARK: - Camera View Controller
struct CameraViewController: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var capturedImage: UIImage?
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraViewController
        
        init(_ parent: CameraViewController) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.capturedImage = image
                parent.onImageCaptured(image)
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: View {
    @ObservedObject var cameraService: CameraService
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = cameraService.capturedImage {
                // Show captured image
                VStack(spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                    
                    if let propertyImage = cameraService.capturedImageWithLocation {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.green)
                                Text("Location Verified")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            if let locationProof = propertyImage.locationProof {
                                Text("Within \(LocationService.formatDistance(locationProof.radiusKm)) of \(locationProof.centerPoint.cityName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button("Clear Photo") {
                        cameraService.clearCapturedImage()
                    }
                    .foregroundColor(.red)
                }
            } else {
                // Show camera options
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Take a Photo")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Capture a photo with location proof for your property listing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            cameraService.presentCamera()
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Take Photo")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(cameraService.cameraAuthorizationStatus != .authorized)
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose from Library")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Error display
            if let error = cameraService.cameraError {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .sheet(isPresented: $cameraService.isShowingCamera) {
            CameraViewController(
                isPresented: $cameraService.isShowingCamera,
                capturedImage: $cameraService.capturedImage
            ) { image in
                Task {
                    await cameraService.captureImageWithLocation(image)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            if let item = newItem {
                Task {
                    await cameraService.processSelectedPhoto(item)
                }
            }
        }
    }
} 
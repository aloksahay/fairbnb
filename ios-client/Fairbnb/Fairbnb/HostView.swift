import SwiftUI

struct HostView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var zkProofService: ZKProofService
    @ObservedObject var cameraService: CameraService
    
    @State private var propertyTitle = ""
    @State private var propertyDescription = ""
    @State private var pricePerNight = ""
    @State private var selectedPropertyType = PropertyType.apartment
    @State private var maxGuests = 1
    @State private var bedrooms = 1
    @State private var bathrooms = 1
    @State private var selectedRadius: Double = 1.0
    @State private var selectedAmenities: Set<String> = []
    
    @State private var currentStep = 1
    @State private var isCreatingListing = false
    @State private var showingSuccess = false
    
    private let totalSteps = 4
    private let availableAmenities = ["WiFi", "Kitchen", "Parking", "Pool", "Gym", "Balcony", "Garden", "Fireplace"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Indicator
                    ProgressIndicator(currentStep: currentStep, totalSteps: totalSteps)
                    
                    // Step Content
                    Group {
                        switch currentStep {
                        case 1:
                            BasicInfoStep(
                                propertyTitle: $propertyTitle,
                                propertyDescription: $propertyDescription,
                                selectedPropertyType: $selectedPropertyType,
                                maxGuests: $maxGuests,
                                bedrooms: $bedrooms,
                                bathrooms: $bathrooms,
                                pricePerNight: $pricePerNight
                            )
                        case 2:
                            LocationProofStep(
                                locationService: locationService,
                                zkProofService: zkProofService,
                                selectedRadius: $selectedRadius
                            )
                        case 3:
                            PhotoStep(cameraService: cameraService)
                        case 4:
                            AmenitiesStep(
                                selectedAmenities: $selectedAmenities,
                                availableAmenities: availableAmenities
                            )
                        default:
                            EmptyView()
                        }
                    }
                    
                    // Navigation Buttons
                    HStack(spacing: 16) {
                        if currentStep > 1 {
                            Button("Previous") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(currentStep == totalSteps ? "Create Listing" : "Next") {
                            if currentStep == totalSteps {
                                createListing()
                            } else {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canProceed ? Color.blue : Color.gray)
                        .cornerRadius(12)
                        .disabled(!canProceed || isCreatingListing)
                        .overlay(
                            Group {
                                if isCreatingListing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Host Your Property")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Listing Created!", isPresented: $showingSuccess) {
                Button("OK") {
                    resetForm()
                }
            } message: {
                Text("Your property has been listed with privacy-preserving location proof!")
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return !propertyTitle.isEmpty && !propertyDescription.isEmpty && !pricePerNight.isEmpty
        case 2:
            return zkProofService.lastProofResult?.isValid == true
        case 3:
            return cameraService.capturedImageWithLocation != nil
        case 4:
            return true // Amenities are optional
        default:
            return false
        }
    }
    
    private func createListing() {
        isCreatingListing = true
        
        // Simulate creating listing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCreatingListing = false
            showingSuccess = true
        }
    }
    
    private func resetForm() {
        currentStep = 1
        propertyTitle = ""
        propertyDescription = ""
        pricePerNight = ""
        selectedPropertyType = .apartment
        maxGuests = 1
        bedrooms = 1
        bathrooms = 1
        selectedRadius = 1.0
        selectedAmenities = []
        cameraService.clearCapturedImage()
    }
}

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            
            Text("Step \(currentStep) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct BasicInfoStep: View {
    @Binding var propertyTitle: String
    @Binding var propertyDescription: String
    @Binding var selectedPropertyType: PropertyType
    @Binding var maxGuests: Int
    @Binding var bedrooms: Int
    @Binding var bathrooms: Int
    @Binding var pricePerNight: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Basic Information")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Property Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Property Type")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(PropertyType.allCases, id: \.self) { type in
                                PropertyTypeCard(
                                    type: type,
                                    isSelected: selectedPropertyType == type
                                ) {
                                    selectedPropertyType = type
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Property Title")
                        .font(.headline)
                    
                    TextField("Beautiful apartment in city center", text: $propertyTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    TextEditor(text: $propertyDescription)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Property Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Property Details")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Max Guests")
                                .font(.subheadline)
                            Stepper(value: $maxGuests, in: 1...16) {
                                Text("\(maxGuests)")
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Bedrooms")
                                .font(.subheadline)
                            Stepper(value: $bedrooms, in: 1...10) {
                                Text("\(bedrooms)")
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Bathrooms")
                                .font(.subheadline)
                            Stepper(value: $bathrooms, in: 1...10) {
                                Text("\(bathrooms)")
                            }
                        }
                    }
                }
                
                // Pricing
                VStack(alignment: .leading, spacing: 8) {
                    Text("Price per Night (USD)")
                        .font(.headline)
                    
                    HStack {
                        Text("$")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        TextField("100", text: $pricePerNight)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct PropertyTypeCard: View {
    let type: PropertyType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LocationProofStep: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var zkProofService: ZKProofService
    @Binding var selectedRadius: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Location Privacy")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Generate a zero-knowledge proof of your property's location to protect your privacy while allowing guests to verify the general area.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Current Location Status
                LocationStatusCard(locationService: locationService)
                
                // Privacy Radius Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy Radius")
                        .font(.headline)
                    
                    Text("Choose how much location privacy you want. Guests will see your property is within this radius but not the exact location.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Radius: \(LocationService.formatDistance(selectedRadius))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("0.5km")
                                .font(.caption)
                            Slider(value: $selectedRadius, in: 0.5...5.0, step: 0.5)
                            Text("5km")
                                .font(.caption)
                        }
                        
                        Text("Smaller radius = more privacy, larger radius = more visibility")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Generate Proof Button
                Button(action: {
                    generateLocationProof()
                }) {
                    HStack {
                        if zkProofService.isGeneratingProof {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "lock.shield")
                        }
                        Text(zkProofService.isGeneratingProof ? "Generating Proof..." : "Generate Location Proof")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(locationService.isLocationEnabled ? Color.purple : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!locationService.isLocationEnabled || zkProofService.isGeneratingProof)
                
                // Proof Result
                if let proofResult = zkProofService.lastProofResult {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: proofResult.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(proofResult.isValid ? .green : .red)
                            Text(proofResult.isValid ? "Location Proof Generated Successfully!" : "Proof Generation Failed")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        if proofResult.isValid {
                            Text("Your property location is now verified within a \(LocationService.formatDistance(selectedRadius)) radius while keeping your exact address private.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(proofResult.isValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if let error = zkProofService.proofError {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func generateLocationProof() {
        guard let currentLocation = locationService.currentLocation else {
            return
        }
        
        let approximateCenter = locationService.suggestApproximateCenter(
            for: currentLocation.coordinate,
            radiusKm: selectedRadius
        )
        
        Task {
            let _ = await zkProofService.generateLocationProof(
                actualLocation: currentLocation.coordinate,
                approximateCenter: approximateCenter,
                radiusKm: selectedRadius
            )
        }
    }
}

struct PhotoStep: View {
    @ObservedObject var cameraService: CameraService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Property Photos")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Take photos of your property with location verification to build trust with potential guests.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                CameraPreview(cameraService: cameraService)
                
                if cameraService.capturedImageWithLocation != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Photo with Location Proof Ready!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text("Your photo has been captured with a privacy-preserving location proof.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct AmenitiesStep: View {
    @Binding var selectedAmenities: Set<String>
    let availableAmenities: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Amenities")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Select the amenities available at your property to help guests find what they need.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(availableAmenities, id: \.self) { amenity in
                        AmenityCard(
                            amenity: amenity,
                            isSelected: selectedAmenities.contains(amenity)
                        ) {
                            if selectedAmenities.contains(amenity) {
                                selectedAmenities.remove(amenity)
                            } else {
                                selectedAmenities.insert(amenity)
                            }
                        }
                    }
                }
                
                if !selectedAmenities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Amenities:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(selectedAmenities.sorted().joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct AmenityCard: View {
    let amenity: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                
                Text(amenity)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HostView(
        locationService: LocationService(),
        zkProofService: ZKProofService(locationService: LocationService()),
        cameraService: CameraService(locationService: LocationService())
    )
} 
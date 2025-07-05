import SwiftUI
import MapKit

struct SearchView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var zkProofService: ZKProofService
    
    @State private var searchText = ""
    @State private var checkInDate = Date()
    @State private var checkOutDate = Date().addingTimeInterval(86400)
    @State private var guests = 1
    @State private var showingFilters = false
    @State private var searchFilters = SearchFilters()
    
    // Sample properties for demonstration
    @State private var properties: [Property] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    // Location Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search destinations", text: $searchText)
                        
                        if !searchText.isEmpty {
                            Button("Clear") {
                                searchText = ""
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Quick Filters
                    HStack {
                        // Date Range
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Check-in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $checkInDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Check-out")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $checkOutDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                        }
                        
                        Spacer()
                        
                        // Guests
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Guests")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Stepper(value: $guests, in: 1...16) {
                                Text("\(guests)")
                                    .font(.subheadline)
                            }
                            .labelsHidden()
                        }
                        
                        // Filters Button
                        Button(action: {
                            showingFilters = true
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color.white)
                .shadow(radius: 1)
                
                // Results
                if properties.isEmpty {
                    EmptySearchView(
                        locationService: locationService,
                        onSearchNearby: searchNearby
                    )
                } else {
                    PropertyListView(
                        properties: properties,
                        zkProofService: zkProofService
                    )
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView(filters: $searchFilters)
            }
            .onAppear {
                loadSampleProperties()
            }
        }
    }
    
    private func searchNearby() {
        guard let approximateLocation = locationService.approximateLocation else {
            return
        }
        
        // Generate sample properties near the user's location
        loadSampleProperties()
    }
    
    private func loadSampleProperties() {
        // Generate sample properties for demonstration
        let sampleProperties = generateSampleProperties()
        properties = sampleProperties
    }
    
    private func generateSampleProperties() -> [Property] {
        guard let userLocation = locationService.approximateLocation else {
            return []
        }
        
        var sampleProperties: [Property] = []
        
        for i in 1...10 {
            // Create random locations within 10km of user
            let randomLatOffset = Double.random(in: -0.1...0.1)
            let randomLonOffset = Double.random(in: -0.1...0.1)
            
            let propertyLocation = ApproximateLocation(
                latitude: userLocation.latitude + randomLatOffset,
                longitude: userLocation.longitude + randomLonOffset,
                cityName: userLocation.cityName,
                countryName: userLocation.countryName
            )
            
            let locationProof = LocationProof(
                proof: "sample_proof_\(i)",
                publicSignals: ["1", "1"],
                radiusKm: Double.random(in: 0.5...3.0),
                centerPoint: propertyLocation,
                isVerified: true
            )
            
            let property = Property(
                id: UUID().uuidString,
                title: "Beautiful \(PropertyType.allCases.randomElement()!.rawValue) \(i)",
                description: "A lovely place to stay with privacy-first location verification.",
                type: PropertyType.allCases.randomElement()!,
                pricePerNight: Double.random(in: 50...300),
                maxGuests: Int.random(in: 1...8),
                bedrooms: Int.random(in: 1...4),
                bathrooms: Int.random(in: 1...3),
                locationProof: locationProof,
                images: [
                    PropertyImage(
                        caption: "Main photo",
                        isPrimary: true
                    )
                ],
                amenities: ["WiFi", "Kitchen", "Parking"].shuffled().prefix(Int.random(in: 1...3)).map(String.init),
                hostId: UUID().uuidString,
                rating: Double.random(in: 3.5...5.0),
                reviewCount: Int.random(in: 0...50),
                isAvailable: true,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            sampleProperties.append(property)
        }
        
        return sampleProperties
    }
}

struct EmptySearchView: View {
    @ObservedObject var locationService: LocationService
    let onSearchNearby: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Find Your Perfect Stay")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Search for properties with privacy-first location verification")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if locationService.isLocationEnabled {
                Button(action: onSearchNearby) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Search Nearby")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    Text("Enable location access to search for nearby properties")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Enable Location") {
                        locationService.requestLocationPermission()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct PropertyListView: View {
    let properties: [Property]
    @ObservedObject var zkProofService: ZKProofService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(properties) { property in
                    PropertyCard(
                        property: property,
                        zkProofService: zkProofService
                    )
                }
            }
            .padding()
        }
    }
}

struct PropertyCard: View {
    let property: Property
    @ObservedObject var zkProofService: ZKProofService
    
    @State private var showingDetails = false
    @State private var isVerifyingProof = false
    @State private var proofVerified: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Property Image Placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Image(systemName: property.type.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Property Photo")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
            
            // Property Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(property.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(Int(property.pricePerNight))")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("per night")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(String(format: "%.1f", property.rating))
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("(\(property.reviewCount) reviews)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(property.bedrooms) bed • \(property.bathrooms) bath")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Location Privacy Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(property.displayLocation)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        LocationProofBadge(
                            locationProof: property.locationProof,
                            isVerifying: isVerifyingProof,
                            isVerified: proofVerified
                        )
                    }
                    
                    Text("Privacy radius: \(LocationService.formatDistance(property.locationProof.radiusKm))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Amenities
                if !property.amenities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(property.amenities, id: \.self) { amenity in
                                Text(amenity)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    verifyLocationProof()
                }) {
                    HStack {
                        if isVerifyingProof {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.shield")
                        }
                        Text("Verify Location")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(isVerifyingProof)
                
                Button(action: {
                    showingDetails = true
                }) {
                    Text("View Details")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
        .sheet(isPresented: $showingDetails) {
            PropertyDetailView(property: property, zkProofService: zkProofService)
        }
    }
    
    private func verifyLocationProof() {
        isVerifyingProof = true
        proofVerified = nil
        
        Task {
            let isValid = await zkProofService.verifyLocationProof(property.locationProof)
            
            await MainActor.run {
                self.isVerifyingProof = false
                self.proofVerified = isValid
            }
        }
    }
}

struct LocationProofBadge: View {
    let locationProof: LocationProof
    let isVerifying: Bool
    let isVerified: Bool?
    
    var body: some View {
        HStack(spacing: 4) {
            if isVerifying {
                ProgressView()
                    .scaleEffect(0.6)
            } else if let isVerified = isVerified {
                Image(systemName: isVerified ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .foregroundColor(isVerified ? .green : .red)
                    .font(.caption)
            } else {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.purple)
                    .font(.caption)
            }
            
            Text(badgeText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var badgeText: String {
        if isVerifying {
            return "Verifying..."
        } else if let isVerified = isVerified {
            return isVerified ? "Verified" : "Invalid"
        } else {
            return "ZK Proof"
        }
    }
    
    private var badgeColor: Color {
        if isVerifying {
            return .orange
        } else if let isVerified = isVerified {
            return isVerified ? .green : .red
        } else {
            return .purple
        }
    }
}

struct PropertyDetailView: View {
    let property: Property
    @ObservedObject var zkProofService: ZKProofService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Property Images
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .cornerRadius(12)
                        .overlay(
                            VStack {
                                Image(systemName: property.type.icon)
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("Property Photos")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        )
                    
                    // Property Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text(property.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(property.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Property specs
                        HStack {
                            PropertySpec(icon: "person.2", text: "\(property.maxGuests) guests")
                            PropertySpec(icon: "bed.double", text: "\(property.bedrooms) bedrooms")
                            PropertySpec(icon: "shower", text: "\(property.bathrooms) bathrooms")
                        }
                        
                        // Location Privacy
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Location Privacy")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "shield.checkered")
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading) {
                                    Text("Zero-Knowledge Location Proof")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Property location verified within \(LocationService.formatDistance(property.locationProof.radiusKm)) radius")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Amenities
                        if !property.amenities.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Amenities")
                                    .font(.headline)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(property.amenities, id: \.self) { amenity in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                            Text(amenity)
                                                .font(.subheadline)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Property Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PropertySpec: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
}

struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Property Type") {
                    ForEach(PropertyType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(.blue)
                            Text(type.rawValue)
                            Spacer()
                            if filters.propertyTypes.contains(type) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if filters.propertyTypes.contains(type) {
                                filters.propertyTypes.remove(type)
                            } else {
                                filters.propertyTypes.insert(type)
                            }
                        }
                    }
                }
                
                Section("Price Range") {
                    VStack {
                        HStack {
                            Text("$\(Int(filters.priceRange.lowerBound))")
                            Spacer()
                            Text("$\(Int(filters.priceRange.upperBound))")
                        }
                        .font(.subheadline)
                        
                        // Note: This is a simplified price range selector
                        // In a real app, you'd use a proper range slider
                        Text("Price range selector would go here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Location Privacy") {
                    Toggle("Require Location Proof", isOn: $filters.requireLocationProof)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        filters = SearchFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SearchView(
        locationService: LocationService(),
        zkProofService: ZKProofService(locationService: LocationService())
    )
} 
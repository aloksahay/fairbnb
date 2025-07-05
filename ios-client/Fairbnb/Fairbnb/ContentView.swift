//
//  ContentView.swift
//  Fairbnb
//
//  Created by Alok Sahay on 05.07.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationService = LocationService()
    @StateObject private var zkProofService: ZKProofService
    @StateObject private var cameraService: CameraService
    
    @State private var selectedTab = 0
    
    init() {
        let locationService = LocationService()
        let zkProofService = ZKProofService(locationService: locationService)
        let cameraService = CameraService(locationService: locationService)
        
        self._zkProofService = StateObject(wrappedValue: zkProofService)
        self._cameraService = StateObject(wrappedValue: cameraService)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView(
                locationService: locationService,
                zkProofService: zkProofService
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Search Tab
            SearchView(
                locationService: locationService,
                zkProofService: zkProofService
            )
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
            .tag(1)
            
            // Host Tab
            HostView(
                locationService: locationService,
                zkProofService: zkProofService,
                cameraService: cameraService
            )
            .tabItem {
                Image(systemName: "plus.circle")
                Text("Host")
            }
            .tag(2)
            
            // Profile Tab
            ProfileView(
                locationService: locationService,
                zkProofService: zkProofService
            )
            .tabItem {
                Image(systemName: "person.circle")
                Text("Profile")
            }
            .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            // Request location permission when app starts
            locationService.requestLocationPermission()
        }
    }
}

struct HomeView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var zkProofService: ZKProofService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome to")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text("FairBnB")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "house.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Privacy-First Home Sharing with Zero-Knowledge Location Proofs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Location Status
                    LocationStatusCard(locationService: locationService)
                    
                    // ZK Proof Demo
                    ZKProofDemoCard(
                        locationService: locationService,
                        zkProofService: zkProofService
                    )
                    
                    // Quick Actions
                    QuickActionsCard(zkProofService: zkProofService)
                    
                    // How It Works
                    HowItWorksCard()
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("FairBnB")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LocationStatusCard: View {
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(locationService.isLocationEnabled ? .green : .orange)
                Text("Location Privacy")
                    .font(.headline)
                Spacer()
            }
            
            if let approximateLocation = locationService.approximateLocation {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Approximate Location:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Text(approximateLocation.cityName.isEmpty ? "Unknown City" : approximateLocation.cityName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Coordinates: \(LocationService.formatApproximateCoordinate(approximateLocation.latitude)), \(LocationService.formatApproximateCoordinate(approximateLocation.longitude))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if locationService.isLocationEnabled {
                Text("Getting your approximate location...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location access is required for privacy-preserving location proofs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Enable Location") {
                        locationService.requestLocationPermission()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            if let error = locationService.locationError {
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
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct ZKProofDemoCard: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var zkProofService: ZKProofService
    
    @State private var selectedRadius: Double = 1.0
    @State private var showingProofDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.purple)
                Text("Zero-Knowledge Location Proof")
                    .font(.headline)
                Spacer()
            }
            
            Text("Generate a cryptographic proof that you're within a radius without revealing your exact location")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Radius Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Privacy Radius: \(LocationService.formatDistance(selectedRadius))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("0.5km")
                        .font(.caption)
                    Slider(value: $selectedRadius, in: 0.5...5.0, step: 0.5)
                    Text("5km")
                        .font(.caption)
                }
            }
            
            // Generate Proof Button
            Button(action: {
                Task {
                    await generateLocationProof()
                }
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
                .font(.subheadline)
                .fontWeight(.medium)
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
                        Text(proofResult.isValid ? "Proof Generated Successfully" : "Proof Generation Failed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Button("View Proof Details") {
                        showingProofDetails = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
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
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
        .sheet(isPresented: $showingProofDetails) {
            ProofDetailsView(proofResult: zkProofService.lastProofResult)
        }
    }
    
    private func generateLocationProof() async {
        guard let currentLocation = locationService.currentLocation else {
            return
        }
        
        let approximateCenter = locationService.suggestApproximateCenter(
            for: currentLocation.coordinate,
            radiusKm: selectedRadius
        )
        
        let _ = await zkProofService.generateLocationProof(
            actualLocation: currentLocation.coordinate,
            approximateCenter: approximateCenter,
            radiusKm: selectedRadius
        )
    }
}

struct QuickActionsCard: View {
    @ObservedObject var zkProofService: ZKProofService
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    icon: "magnifyingglass",
                    title: "Search Properties",
                    color: .blue
                ) {
                    // Navigate to search
                }
                
                QuickActionButton(
                    icon: "plus.circle",
                    title: "List Property",
                    color: .green
                ) {
                    // Navigate to host
                }
                
                QuickActionButton(
                    icon: "shield.checkered",
                    title: "Privacy Settings",
                    color: .purple
                ) {
                    // Navigate to privacy settings
                }
                
                QuickActionButton(
                    icon: "info.circle",
                    title: "Learn More",
                    color: .orange
                ) {
                    // Navigate to info
                }
                
                QuickActionButton(
                    icon: "hammer.circle",
                    title: "Test ZKMoPro",
                    color: .indigo
                ) {
                    Task {
                        let success = await zkProofService.testZKMoproIntegration()
                        await MainActor.run {
                            showingAlert = true
                            alertTitle = "ZKMoPro Integration Test"
                            alertMessage = success ? 
                                "✅ Mock test completed successfully!\n\n💡 To use real ZK proofs:\n1. Add MoproFFI package\n2. Add .zkey files to bundle\n3. Uncomment integration code" :
                                "❌ Test failed"
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HowItWorksCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How Privacy-First Location Works")
                .font(.headline)
            
            VStack(spacing: 16) {
                HowItWorksStep(
                    number: 1,
                    title: "Capture Location",
                    description: "Take a photo or get your current GPS coordinates"
                )
                
                HowItWorksStep(
                    number: 2,
                    title: "Generate ZK Proof",
                    description: "Create a cryptographic proof that you're within a radius"
                )
                
                HowItWorksStep(
                    number: 3,
                    title: "Share Privately",
                    description: "Others can verify your general area without knowing exact location"
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct HowItWorksStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ProofDetailsView: View {
    let proofResult: ZKProofResult?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let result = proofResult {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Proof Status")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result.isValid ? .green : .red)
                                Text(result.isValid ? "Valid" : "Invalid")
                                    .fontWeight(.medium)
                            }
                            
                            if let error = result.error {
                                Text("Error: \(error)")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Public Signals")
                                .font(.headline)
                            
                            ForEach(Array(result.publicSignals.enumerated()), id: \.offset) { index, signal in
                                HStack {
                                    Text("Signal \(index + 1):")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(signal)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Proof Hash")
                                .font(.headline)
                            
                            Text(result.proof.prefix(50) + "...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    } else {
                        Text("No proof data available")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Proof Details")
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

#Preview {
    ContentView()
}

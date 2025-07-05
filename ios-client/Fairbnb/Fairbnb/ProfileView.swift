import SwiftUI

struct ProfileView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var zkProofService: ZKProofService
    
    @State private var userName = "John Doe"
    @State private var userEmail = "john.doe@example.com"
    @State private var isHost = false
    @State private var showingSettings = false
    @State private var showingPrivacySettings = false
    @State private var locationPrivacySettings = LocationPrivacySettings()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView(
                        userName: userName,
                        userEmail: userEmail,
                        isHost: isHost
                    )
                    
                    // Location Privacy Status
                    LocationPrivacyStatusCard(
                        locationService: locationService,
                        zkProofService: zkProofService,
                        privacySettings: locationPrivacySettings
                    ) {
                        showingPrivacySettings = true
                    }
                    
                    // Quick Stats
                    QuickStatsCard()
                    
                    // Menu Options
                    ProfileMenuSection()
                    
                    // Privacy & Security
                    PrivacySecuritySection {
                        showingPrivacySettings = true
                    }
                    
                    // Settings
                    SettingsSection {
                        showingSettings = true
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingPrivacySettings) {
                LocationPrivacySettingsView(
                    locationService: locationService,
                    zkProofService: zkProofService,
                    settings: $locationPrivacySettings
                )
            }
        }
    }
}

struct ProfileHeaderView: View {
    let userName: String
    let userEmail: String
    let isHost: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(userEmail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Host Badge
            if isHost {
                HStack {
                    Image(systemName: "house.fill")
                        .font(.caption)
                    Text("Host")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
        }
        .padding(.top)
    }
}

struct LocationPrivacyStatusCard: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var zkProofService: ZKProofService
    let privacySettings: LocationPrivacySettings
    let onTapSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.purple)
                Text("Location Privacy")
                    .font(.headline)
                Spacer()
                Button("Settings") {
                    onTapSettings()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Privacy Status
                HStack {
                    Image(systemName: locationService.isLocationEnabled ? "location.fill" : "location.slash")
                        .foregroundColor(locationService.isLocationEnabled ? .green : .red)
                    Text(locationService.isLocationEnabled ? "Location Access Enabled" : "Location Access Disabled")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // Default Privacy Radius
                HStack {
                    Image(systemName: "circle.dashed")
                        .foregroundColor(.blue)
                    Text("Default Privacy Radius: \(LocationService.formatDistance(privacySettings.defaultRadiusKm))")
                        .font(.subheadline)
                }
                
                // ZK Proof Status
                if let lastProof = zkProofService.lastProofResult {
                    HStack {
                        Image(systemName: lastProof.isValid ? "checkmark.shield.fill" : "xmark.shield.fill")
                            .foregroundColor(lastProof.isValid ? .green : .red)
                        Text(lastProof.isValid ? "Last Location Proof: Valid" : "Last Location Proof: Invalid")
                            .font(.subheadline)
                    }
                } else {
                    HStack {
                        Image(systemName: "shield")
                            .foregroundColor(.gray)
                        Text("No Location Proofs Generated Yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Quick Actions
                HStack(spacing: 12) {
                    if !locationService.isLocationEnabled {
                        Button("Enable Location") {
                            locationService.requestLocationPermission()
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    Button("Generate Test Proof") {
                        generateTestProof()
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                    .disabled(zkProofService.isGeneratingProof || !locationService.isLocationEnabled)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func generateTestProof() {
        guard let currentLocation = locationService.currentLocation else {
            return
        }
        
        let approximateCenter = locationService.suggestApproximateCenter(
            for: currentLocation.coordinate,
            radiusKm: privacySettings.defaultRadiusKm
        )
        
        Task {
            let _ = await zkProofService.generateLocationProof(
                actualLocation: currentLocation.coordinate,
                approximateCenter: approximateCenter,
                radiusKm: privacySettings.defaultRadiusKm
            )
        }
    }
}

struct QuickStatsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Activity")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(value: "5", label: "Trips", icon: "airplane")
                StatItem(value: "4.8", label: "Rating", icon: "star.fill")
                StatItem(value: "2", label: "Reviews", icon: "text.bubble")
                StatItem(value: "3", label: "ZK Proofs", icon: "shield.checkered")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileMenuSection: View {
    var body: some View {
        VStack(spacing: 0) {
            ProfileMenuRow(
                icon: "calendar",
                title: "My Bookings",
                action: { /* TODO: Navigate to bookings */ }
            )
            
            Divider()
                .padding(.leading, 50)
            
            ProfileMenuRow(
                icon: "heart",
                title: "Wishlist",
                action: { /* TODO: Navigate to wishlist */ }
            )
            
            Divider()
                .padding(.leading, 50)
            
            ProfileMenuRow(
                icon: "star",
                title: "Reviews",
                action: { /* TODO: Navigate to reviews */ }
            )
            
            Divider()
                .padding(.leading, 50)
            
            ProfileMenuRow(
                icon: "house",
                title: "My Properties",
                action: { /* TODO: Navigate to properties */ }
            )
            
            Divider()
                .padding(.leading, 50)
            
            ProfileMenuRow(
                icon: "dollarsign.circle",
                title: "Earnings",
                action: { /* TODO: Navigate to earnings */ }
            )
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct PrivacySecuritySection: View {
    let onPrivacySettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy & Security")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ProfileMenuRow(
                    icon: "shield.checkered",
                    title: "Location Privacy Settings",
                    action: onPrivacySettings
                )
                
                Divider()
                    .padding(.leading, 50)
                
                ProfileMenuRow(
                    icon: "key",
                    title: "ZK Proof History",
                    action: { /* TODO: Navigate to proof history */ }
                )
                
                Divider()
                    .padding(.leading, 50)
                
                ProfileMenuRow(
                    icon: "lock.shield",
                    title: "Data & Privacy",
                    action: { /* TODO: Navigate to data privacy */ }
                )
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 2)
        }
    }
}

struct SettingsSection: View {
    let onSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ProfileMenuRow(
                icon: "gearshape",
                title: "Settings",
                action: onSettings
            )
            
            Divider()
                .padding(.leading, 50)
            
            ProfileMenuRow(
                icon: "questionmark.circle",
                title: "Help & Support",
                action: { /* TODO: Navigate to help */ }
            )
            
            Divider()
                .padding(.leading, 50)
            
            ProfileMenuRow(
                icon: "info.circle",
                title: "About FairBnB",
                action: { /* TODO: Navigate to about */ }
            )
            
            Divider()
                .padding(.leading, 50)
            
            ProfileMenuRow(
                icon: "arrow.right.square",
                title: "Sign Out",
                action: { /* TODO: Implement sign out */ },
                isDestructive: true
            )
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    let isDestructive: Bool
    
    init(icon: String, title: String, action: @escaping () -> Void, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.action = action
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : .blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LocationPrivacySettingsView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject var zkProofService: ZKProofService
    @Binding var settings: LocationPrivacySettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location Privacy")
                            .font(.headline)
                        
                        Text("Control how your location information is shared and protected using zero-knowledge proofs.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Privacy Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Privacy Radius")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Current: \(LocationService.formatDistance(settings.defaultRadiusKm))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("0.5km")
                                .font(.caption)
                            Slider(value: $settings.defaultRadiusKm, in: 0.5...5.0, step: 0.5)
                            Text("5km")
                                .font(.caption)
                        }
                        
                        Text("This radius will be used by default when generating location proofs.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Toggle("Allow Exact Location", isOn: $settings.allowExactLocation)
                    
                    Toggle("Require Location Proof", isOn: $settings.requireLocationProof)
                }
                
                Section("Advanced Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximum Privacy Radius")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Current: \(LocationService.formatDistance(settings.maxRadiusKm))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("1km")
                                .font(.caption)
                            Slider(value: $settings.maxRadiusKm, in: 1.0...10.0, step: 0.5)
                            Text("10km")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Current Status") {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(locationService.isLocationEnabled ? .green : .red)
                        Text("Location Access")
                        Spacer()
                        Text(locationService.isLocationEnabled ? "Enabled" : "Disabled")
                            .foregroundColor(.secondary)
                    }
                    
                    if let approximateLocation = locationService.approximateLocation {
                        HStack {
                            Image(systemName: "mappin.circle")
                                .foregroundColor(.blue)
                            Text("Current City")
                            Spacer()
                            Text(approximateLocation.cityName.isEmpty ? "Unknown" : approximateLocation.cityName)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(.purple)
                        Text("ZK Proofs Generated")
                        Spacer()
                        Text(zkProofService.lastProofResult != nil ? "1" : "0")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Generate Test Proof") {
                        generateTestProof()
                    }
                    .disabled(zkProofService.isGeneratingProof || !locationService.isLocationEnabled)
                    
                    if zkProofService.isGeneratingProof {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating proof...")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let proofResult = zkProofService.lastProofResult {
                        HStack {
                            Image(systemName: proofResult.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(proofResult.isValid ? .green : .red)
                            Text(proofResult.isValid ? "Last proof was valid" : "Last proof was invalid")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Location Privacy")
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
    
    private func generateTestProof() {
        guard let currentLocation = locationService.currentLocation else {
            return
        }
        
        let approximateCenter = locationService.suggestApproximateCenter(
            for: currentLocation.coordinate,
            radiusKm: settings.defaultRadiusKm
        )
        
        Task {
            let _ = await zkProofService.generateLocationProof(
                actualLocation: currentLocation.coordinate,
                approximateCenter: approximateCenter,
                radiusKm: settings.defaultRadiusKm
            )
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account") {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                        Text("Edit Profile")
                    }
                    
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                        Text("Notifications")
                    }
                    
                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundColor(.blue)
                        Text("Payment Methods")
                    }
                }
                
                Section("App") {
                    HStack {
                        Image(systemName: "moon")
                            .foregroundColor(.blue)
                        Text("Dark Mode")
                        Spacer()
                        Toggle("", isOn: .constant(false))
                            .labelsHidden()
                    }
                    
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("Language")
                        Spacer()
                        Text("English")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Support") {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                        Text("Help Center")
                    }
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                        Text("Contact Support")
                    }
                    
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(.blue)
                        Text("Rate App")
                    }
                }
                
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("Terms of Service")
                    }
                    
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(.blue)
                        Text("Privacy Policy")
                    }
                }
            }
            .navigationTitle("Settings")
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
    ProfileView(
        locationService: LocationService(),
        zkProofService: ZKProofService(locationService: LocationService())
    )
} 
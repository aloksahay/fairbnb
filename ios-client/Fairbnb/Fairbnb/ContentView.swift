//
//  ContentView.swift
//  Fairbnb
//
//  Created by Alok Sahay on 05.07.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = PrivyAuthService.shared
    @State private var showingLoginSheet = false
    @State private var showingWalletSheet = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainAppView(authService: authService, showingWalletSheet: $showingWalletSheet)
            } else {
                LoginView(authService: authService, showingLoginSheet: $showingLoginSheet)
            }
        }
        .sheet(isPresented: $showingLoginSheet) {
            EmailLoginView(authService: authService)
        }
        .sheet(isPresented: $showingWalletSheet) {
            WalletView(authService: authService)
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @ObservedObject var authService: PrivyAuthService
    @Binding var showingLoginSheet: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // App Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("FairBnB")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Privacy-First Home Sharing")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Login Button
                Button(action: {
                    showingLoginSheet = true
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Sign In with Email")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
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



// MARK: - Main App View
struct MainAppView: View {
    @ObservedObject var authService: PrivyAuthService
    @Binding var showingWalletSheet: Bool
    @State private var showingProfileMenu = false
    @State private var showingCreateListing = false
    
    var body: some View {
        NavigationView {
            ListingsView()
                .navigationTitle("FairBnB")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showingProfileMenu = true
                        }) {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingCreateListing = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .sheet(isPresented: $showingProfileMenu) {
                    ProfileMenuView(authService: authService, isPresented: $showingProfileMenu)
                }
                .sheet(isPresented: $showingCreateListing) {
                    CreateListingView()
                }
        }
    }
}



// MARK: - Profile Menu View
struct ProfileMenuView: View {
    @ObservedObject var authService: PrivyAuthService
    @Binding var isPresented: Bool
    @StateObject private var selfService = SelfVerificationService()
    @State private var isVerified: Bool? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                }
                .padding()
                
                // Profile Information
                VStack(alignment: .leading, spacing: 16) {
                    ProfileInfoRow(label: "Email", value: authService.currentUser?.email ?? "Not available")
                    
                    if let wallet = authService.userWallet {
                        ProfileInfoRow(label: "Wallet Address", value: wallet.address)
                    } else {
                        ProfileInfoRow(label: "Wallet Address", value: "Loading...")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Verification Status
                if let verified = isVerified {
                    if verified {
                        // Verified status (green)
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Verified Profile")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                                
                                Text("Your identity has been verified")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        // Unverified status (red button)
                        Button(action: {
                            startVerification()
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.red)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unverified Profile")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                    
                                    Text("Tap here to verify")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                } else {
                    // Loading verification status
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Checking verification status...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Sign Out Button
                Button("Sign Out") {
                    Task {
                        await authService.signOut()
                        isPresented = false
                    }
                }
                .foregroundColor(.red)
                .font(.headline)
                .padding()
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                checkVerificationStatus()
            }
        }
    }
    
    // MARK: - Verification Methods
    
    private func checkVerificationStatus() {
        guard let userAddress = authService.currentUser?.walletAddress else {
            isVerified = false
            return
        }
        
        Task {
            // Use the simplified endpoint
            let verified = await selfService.checkVerificationSimple(walletAddress: userAddress)
            
            await MainActor.run {
                isVerified = verified
            }
        }
    }
    
    private func startVerification() {
        guard let userAddress = authService.currentUser?.walletAddress else {
            selfService.errorMessage = "No wallet address found. Please ensure your wallet is connected."
            return
        }
        
        // Close profile menu and start verification
        isPresented = false
        
        print("🧪 Starting Self SDK verification with user wallet address: \(userAddress)")
        
        Task {
            // Start verification with the actual user's wallet address
            await selfService.startVerification(
                userAddress: userAddress
            )
        }
    }
}

// MARK: - Profile Info Row
struct ProfileInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Wallet Card
struct WalletCard: View {
    @ObservedObject var authService: PrivyAuthService
    @Binding var showingWalletSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wallet.pass.fill")
                    .foregroundColor(.green)
                Text("Embedded Wallet")
                    .font(.headline)
                Spacer()
                
                if authService.isWalletLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let wallet = authService.userWallet {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Balance:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(authService.walletBalance) ETH")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Address:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(wallet.displayAddress)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                VStack(spacing: 12) {
                    Button(action: {
                        showingWalletSheet = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Manage Wallet")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
                
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your embedded wallet is being set up...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let error = authService.walletError {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
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

// MARK: - Quick Actions Card
struct QuickActionsCard: View {
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
                    // Coming soon
                }
                
                QuickActionButton(
                    icon: "plus.circle",
                    title: "List Property",
                    color: .green
                ) {
                    // Coming soon
                }
                
                QuickActionButton(
                    icon: "shield.checkered",
                    title: "Privacy Settings",
                    color: .purple
                ) {
                    // Coming soon
                }
                
                QuickActionButton(
                    icon: "info.circle",
                    title: "Learn More",
                    color: .orange
                ) {
                    // Coming soon
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
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
    }
}

// MARK: - App Status Card
struct AppStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Status")
                .font(.headline)
            
            VStack(spacing: 12) {
                StatusRow(title: "Privy Authentication", status: .connected, description: "Email login active")
                StatusRow(title: "Embedded Wallet", status: .connected, description: "Wallet created successfully")
                StatusRow(title: "ZK Location Proofs", status: .pending, description: "Feature coming soon")
                StatusRow(title: "Property Search", status: .pending, description: "Feature coming soon")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct StatusRow: View {
    let title: String
    let status: StatusType
    let description: String
    
    enum StatusType {
        case connected, pending, error
        
        var color: Color {
            switch self {
            case .connected: return .green
            case .pending: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .pending: return "clock.circle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
            
            VStack(alignment: .leading, spacing: 2) {
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



#Preview {
    ContentView()
}

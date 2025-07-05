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
    @State private var showingPrivateKeyExport = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                ListingsView(authService: authService, showingWalletSheet: $showingWalletSheet)
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
        .sheet(isPresented: $showingPrivateKeyExport) {
            NavigationView {
                PrivateKeyExportWebView(
                    appId: "cmcq8l3l2037bju0mf1dc0oou",
                    userEmail: authService.currentUser?.email ?? "no-email@example.com",
                    isPresented: $showingPrivateKeyExport
                )
                .navigationTitle("Export Private Key")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingPrivateKeyExport = false
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPrivateKeyExport)) { _ in
            showingPrivateKeyExport = true
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
                
                // Features
                VStack(spacing: 16) {
                    FeatureRow(icon: "shield.checkered", title: "Zero-Knowledge Privacy", description: "Your exact location stays private")
                    FeatureRow(icon: "wallet.pass", title: "Embedded Wallet", description: "Secure crypto payments built-in")
                    FeatureRow(icon: "lock.shield", title: "Self-Custodial", description: "You control your keys and funds")
                }
                .padding(.horizontal)
                
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
                
                Text("New to FairBnB? Sign up during login")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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



// MARK: - Listings View
struct ListingsView: View {
    @ObservedObject var authService: PrivyAuthService
    @Binding var showingWalletSheet: Bool
    @State private var showingProfileMenu = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Listings Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Listings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // Add Listing Button
                            AddListingCard()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
                
                Spacer()
            }
            .navigationTitle("Listings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingProfileMenu = true
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingProfileMenu) {
                ProfileMenuView(authService: authService, isPresented: $showingProfileMenu)
            }
        }
    }
}

// MARK: - Listing Models
struct Listing {
    let id = UUID()
    let title: String
    let location: String
    let nightlyRate: Int
    let imageName: String
}

// MARK: - Listing Card
struct ListingCard: View {
    let listing: Listing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 120)
                .cornerRadius(12)
                .overlay(
                    Image(systemName: listing.imageName)
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(listing.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("$\(listing.nightlyRate)/night")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .frame(width: 200)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

// MARK: - Add Listing Card
struct AddListingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Add New Listing")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(width: 200, height: 200)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
        )
    }
}

// MARK: - Profile Menu View
struct ProfileMenuView: View {
    @ObservedObject var authService: PrivyAuthService
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Profile")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let user = authService.currentUser {
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                
                // Profile Information
                VStack(alignment: .leading, spacing: 16) {
                    ProfileInfoRow(label: "Email", value: authService.currentUser?.email ?? "Not available")
                    
                    if let wallet = authService.userWallet {
                        ProfileInfoRow(label: "Wallet Address", value: wallet.displayAddress)
                    } else {
                        ProfileInfoRow(label: "Wallet Address", value: "Loading...")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
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
                    
                    // Debug: Export Private Key Options (for development only)
                    HStack(spacing: 8) {
                        // Mock Private Key Export
                        Button(action: {
                            print("Mock private key export - feature coming soon")
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "key.fill")
                                Text("Mock Key")
                                    .font(.caption2)
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Real Private Key Export via WebView
                        Button(action: {
                            print("Real private key export - feature coming soon")
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "globe")
                                Text("Real Key")
                                    .font(.caption2)
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
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

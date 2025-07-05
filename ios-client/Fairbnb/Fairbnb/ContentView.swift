//
//  ContentView.swift
//  Fairbnb
//
//  Created by Alok Sahay on 05.07.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = PrivyAuthService()
    @State private var showingLoginSheet = false
    @State private var showingWalletSheet = false
    @State private var showingPrivateKeyExport = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView(authService: authService, showingWalletSheet: $showingWalletSheet)
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
                    userEmail: authService.currentUser?.email ?? "user@example.com",
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

// MARK: - Main Tab View
struct MainTabView: View {
    @ObservedObject var authService: PrivyAuthService
    @Binding var showingWalletSheet: Bool
    
    var body: some View {
        TabView {
            DashboardView(authService: authService, showingWalletSheet: $showingWalletSheet)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            SelfVerificationView()
                .tabItem {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Verify ID")
                }
            
            WalletTabView(authService: authService, showingWalletSheet: $showingWalletSheet)
                .tabItem {
                    Image(systemName: "wallet.pass.fill")
                    Text("Wallet")
                }
            
            ProfileTabView(authService: authService)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var authService: PrivyAuthService
    @Binding var showingWalletSheet: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back!")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                if let user = authService.currentUser {
                                    Text(user.email)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                } else {
                                    Text("FairBnB User")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Spacer()
                            
                            // Profile Avatar
                            Button(action: {
                                // Profile action
                            }) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Wallet Card
                    WalletCard(authService: authService, showingWalletSheet: $showingWalletSheet)
                    
                    // Quick Actions
                    QuickActionsCard()
                    
                    // App Status
                    AppStatusCard()
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        Task {
                            await authService.signOut()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
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
                            Task {
                                await authService.exportPrivateKey()
                            }
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
                            authService.openPrivateKeyExportWebView()
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

// MARK: - Additional Tab Views

struct WalletTabView: View {
    @ObservedObject var authService: PrivyAuthService
    @Binding var showingWalletSheet: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                WalletCard(authService: authService, showingWalletSheet: $showingWalletSheet)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Wallet")
        }
    }
}

struct ProfileTabView: View {
    @ObservedObject var authService: PrivyAuthService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    if let user = authService.currentUser {
                        Text(user.email)
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                
                // Profile Options
                VStack(spacing: 12) {
                    ProfileOptionRow(icon: "gear", title: "Settings", action: {})
                    ProfileOptionRow(icon: "questionmark.circle", title: "Help & Support", action: {})
                    ProfileOptionRow(icon: "info.circle", title: "About", action: {})
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Sign Out Button
                Button("Sign Out") {
                    Task {
                        await authService.signOut()
                    }
                }
                .foregroundColor(.red)
                .padding()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
        }
    }
}

#Preview {
    ContentView()
}

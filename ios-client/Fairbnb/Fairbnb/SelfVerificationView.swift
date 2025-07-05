import SwiftUI

struct SelfVerificationView: View {
    @StateObject private var selfService = SelfVerificationService()
    @StateObject private var privyAuth = PrivyAuthService.shared
    
    @State private var selectedVerificationType: VerificationType = .guest
    @State private var showingRequirements = false
    @State private var requirements: VerificationRequirements?
    
    enum VerificationType: String, CaseIterable {
        case guest = "guest"
        case host = "host"
        case premium = "premium"
        
        var displayName: String {
            switch self {
            case .guest: return "Guest Verification"
            case .host: return "Host Verification"
            case .premium: return "Premium Verification"
            }
        }
        
        var icon: String {
            switch self {
            case .guest: return "person.fill"
            case .host: return "house.fill"
            case .premium: return "crown.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .guest: return .blue
            case .host: return .green
            case .premium: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if privyAuth.isAuthenticated {
                        verificationStatusSection
                        verificationTypeSelection
                        verificationActionSection
                    } else {
                        authPromptSection
                    }
                }
                .padding()
            }
            .navigationTitle("Identity Verification")
            .onAppear {
                checkCurrentVerificationStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Handle app returning from Self verification
                if selfService.isVerifying {
                    selfService.handleVerificationReturn()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Secure Identity Verification")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Verify your identity using Self's zero-knowledge proof technology. Your passport data stays private.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var authPromptSection: some View {
        VStack(spacing: 16) {
            Text("Sign in to verify your identity")
                .font(.headline)
            
            Text("You need to be signed in with your Privy wallet to start the verification process.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Sign In") {
                // Note: In a real app, you would trigger the login sheet here
                // For now, we'll show a placeholder message
                print("Sign in button tapped - should open login sheet")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var verificationStatusSection: some View {
        VStack(spacing: 16) {
            Text("Current Status")
                .font(.headline)
            
            if let status = selfService.verificationStatus {
                StatusCard(status: status)
            } else {
                Text("Loading verification status...")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var verificationTypeSelection: some View {
        VStack(spacing: 16) {
            Text("Select Verification Level")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(VerificationType.allCases, id: \.self) { type in
                    VerificationTypeCard(
                        type: type,
                        isSelected: selectedVerificationType == type,
                        onTap: {
                            selectedVerificationType = type
                            loadRequirements(for: type)
                        }
                    )
                }
            }
            
            if let requirements = requirements {
                RequirementsCard(requirements: requirements)
            }
        }
    }
    
    private var verificationActionSection: some View {
        VStack(spacing: 16) {
            if selfService.isVerifying {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Opening Self app...")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Complete your verification in the Self app, then return to Fairbnb")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Button(action: startVerification) {
                    HStack {
                        Image(systemName: "person.badge.key.fill")
                        Text("Start \(selectedVerificationType.displayName)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedVerificationType.color)
                    .cornerRadius(12)
                }
                .disabled(!privyAuth.isAuthenticated || privyAuth.currentUser?.walletAddress == nil)
            }
            
            if let errorMessage = selfService.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Actions
    
    private func startVerification() {
        guard let userAddress = privyAuth.currentUser?.walletAddress else {
            selfService.errorMessage = "No wallet address found. Please ensure your Privy wallet is connected."
            return
        }
        
        Task {
            await selfService.startVerification(
                userAddress: userAddress,
                userType: selectedVerificationType.rawValue
            )
        }
    }
    
    private func checkCurrentVerificationStatus() {
        guard let userAddress = privyAuth.currentUser?.walletAddress else { return }
        
        Task {
            await selfService.checkVerificationStatus(userAddress: userAddress)
        }
    }
    
    private func loadRequirements(for type: VerificationType) {
        Task {
            requirements = await selfService.getVerificationRequirements(userType: type.rawValue)
        }
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let status: SelfVerificationStatus
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Guest", systemImage: status.isVerifiedGuest ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(status.isVerifiedGuest ? .green : .red)
                    
                    Label("Host", systemImage: status.isVerifiedHost ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(status.isVerifiedHost ? .green : .red)
                    
                    Label("Premium", systemImage: status.isPremiumUser ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(status.isPremiumUser ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Valid")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(status.isValid ? "✓" : "✗")
                        .font(.title2)
                        .foregroundColor(status.isValid ? .green : .red)
                }
            }
            
            if status.verificationTimestamp > 0 {
                Text("Last verified: \(Date(timeIntervalSince1970: TimeInterval(status.verificationTimestamp)).formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct VerificationTypeCard: View {
    let type: SelfVerificationView.VerificationType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 30))
                .foregroundColor(isSelected ? .white : type.color)
            
            Text(type.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(isSelected ? type.color : Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture(perform: onTap)
    }
}

struct RequirementsCard: View {
    let requirements: VerificationRequirements
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requirements")
                .font(.headline)
            
            Text(requirements.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Minimum Age: \(requirements.minimumAge)", systemImage: "calendar")
                
                if requirements.ofacRequired {
                    Label("OFAC Compliance Check", systemImage: "checkmark.shield")
                }
                
                if requirements.geographicRestrictions {
                    Label("Geographic Restrictions Apply", systemImage: "globe")
                }
                
                if !requirements.requiredFields.isEmpty {
                    Label("Required: \(requirements.requiredFields.joined(separator: ", "))", systemImage: "doc.text")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    SelfVerificationView()
} 
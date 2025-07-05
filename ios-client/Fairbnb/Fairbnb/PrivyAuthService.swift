import Foundation
import SwiftUI
import PrivySDK

// Notification for opening private key export WebView
extension Notification.Name {
    static let openPrivateKeyExport = Notification.Name("openPrivateKeyExport")
}

class PrivyAuthService: ObservableObject {
    static let shared = PrivyAuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: PrivyUserModel?
    @Published var userWallet: PrivyWalletModel?
    @Published var isLoading = false
    @Published var authError: PrivyAuthError?
    
    // Email OTP flow state
    @Published var otpFlowState: OTPFlowState = .initial
    @Published var pendingEmail: String = ""
    
    // Wallet state
    @Published var walletBalance: String = "0.00"
    @Published var isWalletLoading = false
    @Published var walletError: PrivyWalletError?
    
    // MARK: - Configuration
    private let privyAppId = "cmcq8l3l2037bju0mf1dc0oou" // Replace with your Privy App ID
    private let privyAppClientId = "client-WY6N5YcRGgAs1RLAeYKffkdyzGXCXvhxHp6iAP418fJ5F" // Add your App Client ID from Privy Dashboard
    private var privy: Privy?
    
    private init() {
        // Initialize Privy SDK
        initializePrivy()
        
        // Check for existing authentication
        checkAuthenticationStatus()
    }
    
    // MARK: - Privy SDK Initialization
    
    private func initializePrivy() {
        // MARK: - Real Privy Initialization
        // Based on https://docs.privy.io/basics/swift/setup
        
        let config = PrivyConfig(
            appId: privyAppId,
            appClientId: privyAppClientId,
            loggingConfig: .init(
                logLevel: .verbose
            )
        )
        
        self.privy = PrivySdk.initialize(config: config)
        
        // Wait for Privy to be ready
        awaitPrivySDKReady()
        
        print("✅ Privy SDK initialized with App ID: \(privyAppId)")
        
        // MARK: - Mock Initialization (for fallback)
        // print("🔄 Mock Privy initialization")
        // print("   💡 Add PrivySDK package and configure App Client ID")
    }
    
    private func awaitPrivySDKReady() {
        Task {
            guard let privy = self.privy else { return }
            
            // Show loading state
            await MainActor.run {
                self.isLoading = true
            }
            
            // Await privy ready
            await privy.awaitReady()
            
            print("Privy SDK is ready!")
            
            // Check user auth state
            await MainActor.run {
                switch privy.authState {
                case .authenticated(let privyUser):
                    // User is authenticated
                    self.handleAuthenticatedUser(privyUser)
                case .unauthenticated:
                    // User is not authenticated
                    self.isAuthenticated = false
                    self.currentUser = nil
                case .notReady, .authenticatedUnverified(_):
                    // Still initializing
                    break
                @unknown default:
                    break
                }
                
                self.isLoading = false
            }
        }
    }
    
    private func handleAuthenticatedUser(_ privyUser: Any) {
        // Convert Privy user to our model
        // Note: You'll need to implement this based on the actual PrivyUser structure
        
        /*
        let user = PrivyUserModel(
            id: privyUser.id,
            email: privyUser.email?.address ?? "",
            walletAddress: privyUser.wallet?.address ?? "",
            createdAt: privyUser.createdAt,
            isEmailVerified: privyUser.email?.verified ?? false
        )
        
        self.currentUser = user
        self.isAuthenticated = true
        
        // Load user's wallet if available
        Task {
            await loadUserWallet()
        }
        */
        
        // Mock implementation for now
        let mockUser = PrivyUserModel(
            id: "authenticated_user_\(UUID().uuidString.prefix(8))",
            email: "user@example.com",
            walletAddress: generateMockWalletAddress(),
            createdAt: Date(),
            isEmailVerified: true
        )
        
        self.currentUser = mockUser
        self.isAuthenticated = true
        
        Task {
            await createMockWallet()
        }
    }
    
    private func checkAuthenticationStatus() {
        // MARK: - Real Authentication Check
        // Uncomment once you have PrivySDK package integrated:
        
        /*
        if let user = Privy.user {
            self.currentUser = PrivyUserModel.from(privyUser: user)
            self.isAuthenticated = true
            
            // Load user's wallet if available
            loadUserWallet()
        }
        */
        
        // MARK: - Mock Authentication Check
        // Simulate checking for existing auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // No existing auth in mock mode
            self.isAuthenticated = false
        }
    }
    
    // MARK: - Email Authentication
    
    /// Send OTP code to user's email
    func sendEmailCode(to email: String) async {
        await MainActor.run {
            self.isLoading = true
            self.otpFlowState = .sendingCode
            self.authError = nil
            self.pendingEmail = email
        }
        
        do {
            // MARK: - Real Privy Email OTP
            // Using the correct Privy Swift API
            
            guard let privy = self.privy else {
                throw PrivyAuthError.unknown(NSError(domain: "Privy not initialized", code: -1))
            }
            
            try await privy.email.sendCode(to: email)
            
            await MainActor.run {
                self.otpFlowState = .awaitingCodeInput
                self.isLoading = false
            }
            
            print("✅ OTP sent to \(email)")
            
            // MARK: - Mock Email OTP
            // Simulate sending OTP
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                self.otpFlowState = .awaitingCodeInput
                self.isLoading = false
            }
            
            print("🔄 Mock OTP sent to \(email)")
            print("   💡 Use any 6-digit code to continue (e.g., 123456)")
            
        } catch {
            await MainActor.run {
                self.authError = .emailSendFailed(error)
                self.otpFlowState = .error
                self.isLoading = false
            }
            
            print("❌ Failed to send OTP: \(error)")
        }
    }
    
    /// Verify OTP code and authenticate user
    func verifyEmailCode(_ code: String) async {
        await MainActor.run {
            self.isLoading = true
            self.otpFlowState = .submittingCode
            self.authError = nil
        }
        
        do {
            // Store email before clearing pendingEmail
            let userEmail = pendingEmail
            
            // MARK: - Real Privy Email Verification
            // Using the correct Privy Swift API
            
            /*
            guard let privy = self.privy else {
                throw PrivyAuthError.unknown(NSError(domain: "Privy not initialized", code: -1))
            }
            
            _ = try await privy.email.loginWithCode(code, sentTo: userEmail)
            
            await MainActor.run {
                // Convert to our model - you'll need to implement PrivyUserModel.from based on actual PrivyUser structure
                // self.currentUser = PrivyUserModel.from(privyUser: privyUser)
                
                // For now, create a user with real authentication
                let user = PrivyUserModel(
                    id: "privy_user_\(UUID().uuidString.prefix(8))",
                    email: userEmail,
                    walletAddress: generateMockWalletAddress(),
                    createdAt: Date(),
                    isEmailVerified: true
                )
                
                self.currentUser = user
                self.isAuthenticated = true
                self.otpFlowState = .done
                self.isLoading = false
                self.pendingEmail = ""
            }
            
            // Load or create user's wallet
            await loadUserWallet()
            
            print("✅ User authenticated successfully")
            print("   User authenticated via Privy")
            */
            
            // MARK: - Mock Email Verification
            // Simulate code verification
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Mock successful authentication
            let mockUser = PrivyUserModel(
                id: "mock_user_\(UUID().uuidString.prefix(8))",
                email: userEmail,
                walletAddress: generateMockWalletAddress(),
                createdAt: Date(),
                isEmailVerified: true
            )
            
            await MainActor.run {
                self.currentUser = mockUser
                self.isAuthenticated = true
                self.otpFlowState = .done
                self.isLoading = false
                self.pendingEmail = ""
            }
            
            // Create mock wallet
            await createMockWallet()
            
            print("✅ Mock user authenticated successfully")
            print("   Email: \(mockUser.email)")
            print("   Wallet: \(mockUser.walletAddress)")
            
        } catch {
            await MainActor.run {
                self.authError = .emailVerificationFailed(error)
                self.otpFlowState = .error
                self.isLoading = false
            }
            
            print("❌ Failed to verify OTP: \(error)")
        }
    }
    
    // MARK: - Wallet Management
    
    /// Load user's embedded wallet
    func loadUserWallet() async {
        await MainActor.run {
            self.isWalletLoading = true
            self.walletError = nil
        }
        
        do {
            // MARK: - Real Privy Wallet Loading
            // Uncomment once you have PrivySDK package integrated:
            
            /*
            // Get user's embedded wallet
            if let wallet = Privy.user?.wallet {
                let balance = try await wallet.getBalance()
                
                await MainActor.run {
                    self.userWallet = PrivyWalletModel.from(privyWallet: wallet)
                    self.walletBalance = formatBalance(balance)
                    self.isWalletLoading = false
                }
                
                print("✅ Wallet loaded successfully")
                print("   Address: \(wallet.address)")
                print("   Balance: \(balance)")
            }
            */
            
            // MARK: - Mock Wallet Loading
            await createMockWallet()
            
        } catch {
            await MainActor.run {
                self.walletError = .loadingFailed(error)
                self.isWalletLoading = false
            }
            
            print("❌ Failed to load wallet: \(error)")
        }
    }
    
    /// Create or retrieve user's embedded wallet
    func createWallet() async {
        await MainActor.run {
            self.isWalletLoading = true
            self.walletError = nil
        }
        
        do {
            // MARK: - Real Privy Wallet Creation
            // Uncomment once you have PrivySDK package integrated:
            
            /*
            let wallet = try await Privy.createWallet()
            
            await MainActor.run {
                self.userWallet = PrivyWalletModel.from(privyWallet: wallet)
                self.isWalletLoading = false
            }
            
            print("✅ Wallet created successfully")
            print("   Address: \(wallet.address)")
            */
            
            // MARK: - Mock Wallet Creation
            await createMockWallet()
            
        } catch {
            await MainActor.run {
                self.walletError = .creationFailed(error)
                self.isWalletLoading = false
            }
            
            print("❌ Failed to create wallet: \(error)")
        }
    }
    
    /// Get wallet balance
    func refreshWalletBalance() async {
        guard let wallet = userWallet else { return }
        
        await MainActor.run {
            self.isWalletLoading = true
        }
        
        do {
            // MARK: - Real Balance Refresh
            // Uncomment once you have PrivySDK package integrated:
            
            /*
            let balance = try await privyWallet.getBalance()
            
            await MainActor.run {
                self.walletBalance = formatBalance(balance)
                self.isWalletLoading = false
            }
            
            print("✅ Balance refreshed: \(balance)")
            */
            
            // MARK: - Mock Balance Refresh
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let mockBalance = Double.random(in: 0...100)
            
            await MainActor.run {
                self.walletBalance = String(format: "%.4f", mockBalance)
                self.isWalletLoading = false
            }
            
            print("🔄 Mock balance refreshed: \(mockBalance)")
            
        } catch {
            await MainActor.run {
                self.walletError = .balanceRefreshFailed(error)
                self.isWalletLoading = false
            }
            
            print("❌ Failed to refresh balance: \(error)")
        }
    }

    
    /// Send transaction from user's wallet
    func sendTransaction(to recipient: String, amount: String, chainId: String = "1") async -> Bool {
        guard let wallet = userWallet else {
            await MainActor.run {
                self.walletError = .noWalletFound
            }
            return false
        }
        
        await MainActor.run {
            self.isWalletLoading = true
            self.walletError = nil
        }
        
        do {
            // MARK: - Real Transaction
            // Uncomment once you have PrivySDK package integrated:
            
            /*
            let transaction = try await wallet.sendTransaction(
                to: recipient,
                value: amount,
                chainId: chainId
            )
            
            await MainActor.run {
                self.isWalletLoading = false
            }
            
            print("✅ Transaction sent successfully")
            print("   Hash: \(transaction.hash)")
            
            return true
            */
            
            // MARK: - Mock Transaction
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                self.isWalletLoading = false
            }
            
            print("🔄 Mock transaction sent")
            print("   To: \(recipient)")
            print("   Amount: \(amount)")
            print("   Chain: \(chainId)")
            
            return true
            
        } catch {
            await MainActor.run {
                self.walletError = .transactionFailed(error)
                self.isWalletLoading = false
            }
            
            print("❌ Transaction failed: \(error)")
            return false
        }
    }
    
    // MARK: - Authentication Management
    
    /// Sign out user and clear authentication state
    func signOut() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        // MARK: - Real Privy Sign Out
        // Note: Privy Swift SDK doesn't have a logout() method
        // Authentication state is managed automatically by the SDK
        // We just need to clear local state
        
        // Clear local state
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUser = nil
            self.userWallet = nil
            self.walletBalance = "0.00"
            self.otpFlowState = .initial
            self.pendingEmail = ""
            self.authError = nil
            self.walletError = nil
            self.isLoading = false
        }
        
        print("✅ User signed out successfully")
    }
    
    /// Reset authentication flow state
    func resetAuthFlow() {
        otpFlowState = .initial
        pendingEmail = ""
        authError = nil
    }
    
    // MARK: - Private Helpers
    

    
    private func createMockWallet() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let mockWallet = PrivyWalletModel(
            address: currentUser?.walletAddress ?? generateMockWalletAddress(),
            chainId: "1", // Ethereum mainnet
            balance: "0.0000",
            isEmbedded: true,
            createdAt: Date()
        )
        
        await MainActor.run {
            self.userWallet = mockWallet
            self.walletBalance = mockWallet.balance
            self.isWalletLoading = false
        }
        
        print("🔄 Mock wallet created")
        print("   Address: \(mockWallet.address)")
    }
    
    private func generateMockWalletAddress() -> String {
        let hex = "0123456789abcdef"
        let address = "0x" + String((0..<40).map { _ in hex.randomElement()! })
        return address
    }
    
    private func generateMockPrivateKey() -> String {
        let hex = "0123456789abcdef"
        let privateKey = String((0..<64).map { _ in hex.randomElement()! })
        return privateKey
    }
    
    private func formatBalance(_ balance: Double) -> String {
        return String(format: "%.4f", balance)
    }
}

// MARK: - Models

struct PrivyUserModel: Identifiable, Codable {
    let id: String
    let email: String
    let walletAddress: String
    let createdAt: Date
    let isEmailVerified: Bool
    
    // Convert from Privy SDK user object
    /*
    static func from(privyUser: PrivyUser) -> PrivyUserModel {
        return PrivyUserModel(
            id: privyUser.id,
            email: privyUser.email?.address ?? "",
            walletAddress: privyUser.wallet?.address ?? "",
            createdAt: privyUser.createdAt,
            isEmailVerified: privyUser.email?.verified ?? false
        )
    }
    */
}

struct PrivyWalletModel: Identifiable, Codable {
    var id = UUID()
    let address: String
    let chainId: String
    let balance: String
    let isEmbedded: Bool
    let createdAt: Date
    
    var displayAddress: String {
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
    
    var chainName: String {
        switch chainId {
        case "1": return "Ethereum"
        case "137": return "Polygon"
        case "8453": return "Base"
        case "42161": return "Arbitrum"
        default: return "Unknown"
        }
    }
    
    // Convert from Privy SDK wallet object
    /*
    static func from(privyWallet: PrivyWallet) -> PrivyWalletModel {
        return PrivyWalletModel(
            address: privyWallet.address,
            chainId: privyWallet.chainId,
            balance: "0.0000", // Will be updated separately
            isEmbedded: true,
            createdAt: Date()
        )
    }
    */
}

// MARK: - Flow States

enum OTPFlowState {
    case initial
    case sendingCode
    case awaitingCodeInput
    case submittingCode
    case done
    case error
    
    var description: String {
        switch self {
        case .initial: return "Ready to send code"
        case .sendingCode: return "Sending verification code..."
        case .awaitingCodeInput: return "Enter the code sent to your email"
        case .submittingCode: return "Verifying code..."
        case .done: return "Authentication complete"
        case .error: return "Authentication error"
        }
    }
}

// MARK: - Error Types

enum PrivyAuthError: Error, LocalizedError {
    case emailSendFailed(Error)
    case emailVerificationFailed(Error)
    case invalidCode
    case networkError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .emailSendFailed(let error):
            return "Failed to send verification code: \(error.localizedDescription)"
        case .emailVerificationFailed(let error):
            return "Failed to verify code: \(error.localizedDescription)"
        case .invalidCode:
            return "Invalid verification code. Please try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emailSendFailed:
            return "Check your internet connection and try again."
        case .emailVerificationFailed, .invalidCode:
            return "Make sure you entered the correct 6-digit code from your email."
        case .networkError:
            return "Check your internet connection and try again."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}

enum PrivyWalletError: Error, LocalizedError {
    case noWalletFound
    case creationFailed(Error)
    case loadingFailed(Error)
    case balanceRefreshFailed(Error)
    case transactionFailed(Error)
    case insufficientFunds
    case invalidAddress
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noWalletFound:
            return "No wallet found. Please create a wallet first."
        case .creationFailed(let error):
            return "Failed to create wallet: \(error.localizedDescription)"
        case .loadingFailed(let error):
            return "Failed to load wallet: \(error.localizedDescription)"
        case .balanceRefreshFailed(let error):
            return "Failed to refresh balance: \(error.localizedDescription)"
        case .transactionFailed(let error):
            return "Transaction failed: \(error.localizedDescription)"
        case .insufficientFunds:
            return "Insufficient funds for this transaction."
        case .invalidAddress:
            return "Invalid wallet address."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noWalletFound:
            return "Create a new wallet from your profile settings."
        case .creationFailed, .loadingFailed:
            return "Check your internet connection and try again."
        case .balanceRefreshFailed:
            return "Try refreshing again in a few moments."
        case .transactionFailed:
            return "Check the recipient address and amount, then try again."
        case .insufficientFunds:
            return "Add funds to your wallet before making this transaction."
        case .invalidAddress:
            return "Double-check the recipient wallet address."
        case .networkError:
            return "Check your internet connection and try again."
        }
    }
} 

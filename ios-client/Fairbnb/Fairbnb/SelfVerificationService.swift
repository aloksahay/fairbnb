import Foundation
import UIKit

// Self Configuration Structure (matches backend)
struct SelfConfig: Codable {
    let appName: String
    let scope: String
    let endpoint: String
    let logoBase64: String?
    let userId: String
    let userIdType: String
    let version: Int
    let userDefinedData: String
    let disclosures: SelfDisclosures
}

struct SelfDisclosures: Codable {
    // Identity fields (optional)
    let issuing_state: Bool?
    let name: Bool?
    let passport_number: Bool?
    let nationality: Bool?
    let date_of_birth: Bool?
    let gender: Bool?
    let expiry_date: Bool?
    
    // Verification requirements
    let minimumAge: Int?
    let excludedCountries: [String]?
    let ofac: Bool?
}

// Verification Result
struct SelfVerificationResult: Codable {
    let success: Bool
    let userAddress: String
    let userType: String
    let timestamp: Int
    let transactionHash: String?
    let error: String?
}

// Verification Status
struct SelfVerificationStatus: Codable {
    let isVerifiedHost: Bool
    let isVerifiedGuest: Bool
    let isPremiumUser: Bool
    let verificationTimestamp: Int
    let isValid: Bool
}

@MainActor
class SelfVerificationService: ObservableObject {
    @Published var isVerifying = false
    @Published var verificationResult: SelfVerificationResult?
    @Published var verificationStatus: SelfVerificationStatus?
    @Published var errorMessage: String?
    
    private let baseURL = "http://localhost:3000/api/self-verification"
    
    // MARK: - Verification Flow
    
    /// Start verification process for a Privy wallet user
    func startVerification(userAddress: String, userType: String) async {
        await MainActor.run {
            self.isVerifying = true
            self.errorMessage = nil
        }
        
        do {
            // Step 1: Get Self configuration from backend
            let config = try await getSelfConfig(userAddress: userAddress, userType: userType)
            
            // Step 2: Generate deeplink and redirect to Self app
            await openSelfApp(with: config)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to start verification: \(error.localizedDescription)"
                self.isVerifying = false
            }
        }
    }
    
    /// Get Self configuration from backend
    private func getSelfConfig(userAddress: String, userType: String) async throws -> SelfConfig {
        guard let url = URL(string: "\(baseURL)/config?userAddress=\(userAddress)&userType=\(userType)") else {
            throw SelfVerificationError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SelfVerificationError.networkError
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<SelfConfig>.self, from: data)
        
        guard apiResponse.success, let config = apiResponse.data else {
            throw SelfVerificationError.configurationFailed
        }
        
        return config
    }
    
    /// Open Self app using deeplink
    private func openSelfApp(with config: SelfConfig) async {
        // Generate the deeplink URL based on Self's V2 protocol
        let deeplink = generateSelfDeeplink(config: config)
        
        await MainActor.run {
            if let url = URL(string: deeplink) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url) { success in
                        if !success {
                            self.errorMessage = "Failed to open Self app. Please install Self from the App Store."
                            self.isVerifying = false
                        }
                    }
                } else {
                    // Fallback: Open Self app store page
                    self.openSelfAppStore()
                }
            } else {
                self.errorMessage = "Invalid deeplink generated"
                self.isVerifying = false
            }
        }
    }
    
    /// Generate Self deeplink based on configuration
    private func generateSelfDeeplink(config: SelfConfig) -> String {
        // Based on Self's deeplinking documentation
        // This generates a universal link that opens the Self mobile app
        
        let baseURL = "https://app.self.xyz/verify"
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "appName", value: config.appName),
            URLQueryItem(name: "scope", value: config.scope),
            URLQueryItem(name: "endpoint", value: config.endpoint),
            URLQueryItem(name: "userId", value: config.userId),
            URLQueryItem(name: "userIdType", value: config.userIdType),
            URLQueryItem(name: "version", value: String(config.version)),
            URLQueryItem(name: "userDefinedData", value: config.userDefinedData),
            
            // Disclosures
            URLQueryItem(name: "minimumAge", value: config.disclosures.minimumAge.map(String.init)),
            URLQueryItem(name: "ofac", value: config.disclosures.ofac.map(String.init)),
            URLQueryItem(name: "name", value: config.disclosures.name.map(String.init)),
            URLQueryItem(name: "nationality", value: config.disclosures.nationality.map(String.init)),
            URLQueryItem(name: "date_of_birth", value: config.disclosures.date_of_birth.map(String.init)),
            URLQueryItem(name: "issuing_state", value: config.disclosures.issuing_state.map(String.init)),
            URLQueryItem(name: "passport_number", value: config.disclosures.passport_number.map(String.init)),
            URLQueryItem(name: "gender", value: config.disclosures.gender.map(String.init)),
            URLQueryItem(name: "expiry_date", value: config.disclosures.expiry_date.map(String.init))
        ]
        
        // Add excluded countries if any
        if let excludedCountries = config.disclosures.excludedCountries {
            components.queryItems?.append(
                URLQueryItem(name: "excludedCountries", value: excludedCountries.joined(separator: ","))
            )
        }
        
        return components.url?.absoluteString ?? baseURL
    }
    
    /// Open Self app in App Store
    private func openSelfAppStore() {
        let appStoreURL = "https://apps.apple.com/app/self-identity/id1234567890" // Replace with actual Self app ID
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
        self.isVerifying = false
    }
    
    // MARK: - Status Checking
    
    /// Check verification status for a user
    func checkVerificationStatus(userAddress: String) async {
        do {
            guard let url = URL(string: "\(baseURL)/status/\(userAddress)") else {
                throw SelfVerificationError.invalidURL
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SelfVerificationError.networkError
            }
            
            let apiResponse = try JSONDecoder().decode(APIResponse<SelfVerificationStatus>.self, from: data)
            
            await MainActor.run {
                if apiResponse.success {
                    self.verificationStatus = apiResponse.data
                } else {
                    self.errorMessage = "Failed to get verification status"
                }
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Error checking status: \(error.localizedDescription)"
            }
        }
    }
    
    /// Get verification requirements for a user type
    func getVerificationRequirements(userType: String) async -> VerificationRequirements? {
        do {
            guard let url = URL(string: "\(baseURL)/requirements/\(userType)") else {
                return nil
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let apiResponse = try JSONDecoder().decode(APIResponse<VerificationRequirements>.self, from: data)
            return apiResponse.data
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Error getting requirements: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    // MARK: - App State Management
    
    /// Handle app returning from Self verification
    func handleVerificationReturn() {
        // This should be called when the app returns from Self
        // You can implement polling or webhook handling here
        Task {
            // Wait a moment for the verification to process
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Check if we have a user address to verify
            if let userAddress = getCurrentUserAddress() {
                await checkVerificationStatus(userAddress: userAddress)
            }
            
            await MainActor.run {
                self.isVerifying = false
            }
        }
    }
    
    /// Get current user's Privy wallet address
    private func getCurrentUserAddress() -> String? {
        // Use the shared auth service instance
        return PrivyAuthService.shared.currentUser?.walletAddress
    }
    
    /// Reset verification state
    func resetVerificationState() {
        isVerifying = false
        verificationResult = nil
        verificationStatus = nil
        errorMessage = nil
    }
}

// MARK: - Supporting Types

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct VerificationRequirements: Codable {
    let minimumAge: Int
    let requiredFields: [String]
    let ofacRequired: Bool
    let geographicRestrictions: Bool
    let excludedCountries: [String]?
    let description: String
}

enum SelfVerificationError: LocalizedError {
    case invalidURL
    case networkError
    case configurationFailed
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error"
        case .configurationFailed:
            return "Failed to get verification configuration"
        case .verificationFailed:
            return "Verification failed"
        }
    }
}

// MARK: - Privy Integration Extension
// Note: PrivyUserModel already has walletAddress property, no extension needed 
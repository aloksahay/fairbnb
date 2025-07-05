import Foundation
import CoreLocation
// MARK: - ZKMoPro Integration
// To complete the integration with the official ZKMoPro Swift Package:
// 1. Add the package dependency to your Xcode project:
//    File > Add Package Dependencies > https://github.com/zkmopro/mopro-swift-package
// 2. Import MoproFFI below:
// import MoproFFI

// NOTE: This service provides the structure for ZKMoPro integration
// The official mopro-swift-package makes integration much simpler than manual bindings

class ZKProofService: ObservableObject {
    @Published var isGeneratingProof = false
    @Published var lastProofResult: ZKProofResult?
    @Published var proofError: ZKProofError?
    
    private let locationService: LocationService
    
    // ZK Circuit configuration
    // The default package comes with multiplier2 circuit
    // You can replace this with your custom location proof circuit
    private let circuitName = "location_proof" // Your custom circuit name
    private let zkeyFileName = "location_proof_final.zkey" // Your custom .zkey file
    
    // For testing with the default multiplier2 circuit:
    private let defaultCircuitName = "multiplier2_final"
    
    init(locationService: LocationService) {
        self.locationService = locationService
    }
    
    // MARK: - ZK Proof Generation
    
    /// Generate a ZK proof that a location is within a specified radius without revealing the exact location
    func generateLocationProof(
        actualLocation: CLLocationCoordinate2D,
        approximateCenter: CLLocationCoordinate2D,
        radiusKm: Double
    ) async -> ZKProofResult {
        
        await MainActor.run {
            self.isGeneratingProof = true
            self.proofError = nil
        }
        
        do {
            // Validate that the actual location is within the radius
            guard actualLocation.isWithinRadius(radiusKm, of: approximateCenter) else {
                throw ZKProofError.locationOutsideRadius
            }
            
            // Create proof inputs
            let proofInput = locationService.createLocationProofInput(
                actualLocation: actualLocation,
                approximateCenter: approximateCenter,
                radiusKm: radiusKm
            )
            
            // Generate the ZK proof
            let result = try await generateZKProof(input: proofInput)
            
            await MainActor.run {
                self.lastProofResult = result
                self.isGeneratingProof = false
            }
            
            return result
            
        } catch {
            let zkError = error as? ZKProofError ?? .unknown(error)
            
            await MainActor.run {
                self.proofError = zkError
                self.isGeneratingProof = false
            }
            
            return ZKProofResult(
                proof: "",
                publicSignals: [],
                isValid: false,
                error: zkError.localizedDescription
            )
        }
    }
    
    /// Generate ZK proof using ZKMoPro Swift Package
    private func generateZKProof(input: ZKProofInput) async throws -> ZKProofResult {
        
        // MARK: - Option 1: Use Custom Location Proof Circuit (Recommended for Production)
        /*
        // Get the path to your custom location proof circuit
        guard let zkeyPath = Bundle.main.path(forResource: circuitName, ofType: "zkey") else {
            throw ZKProofError.circuitNotFound
        }
        
        // Convert inputs to ZKMoPro format
        let zkInputs = input.toZKInputs()
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Generate the proof using ZKMoPro Swift Package
            let generateProofResult = try generateCircomProof(
                zkeyPath: zkeyPath,
                circuitInputs: zkInputs,
                proofLib: ProofLib.arkworks
            )
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let proofTime = endTime - startTime
            
            print("✅ ZK Location Proof generated in \(String(format: "%.3f", proofTime))s")
            
            return ZKProofResult(
                proof: generateProofResult.proof,
                publicSignals: generateProofResult.inputs,
                isValid: true
            )
            
        } catch {
            print("❌ ZK Proof generation failed: \(error)")
            throw ZKProofError.proofGenerationFailed(error)
        }
        */
        
        // MARK: - Option 2: Test with Default Multiplier2 Circuit
        /*
        // For testing purposes, you can use the default multiplier2 circuit
        // Download the zkey from: http://ci-keys.zkmopro.org/multiplier2_final.zkey
        // Add it to your Xcode project bundle resources
        
        guard let zkeyPath = Bundle.main.path(forResource: defaultCircuitName, ofType: "zkey") else {
            throw ZKProofError.circuitNotFound
        }
        
        // Create test inputs for multiplier2 circuit (a * b = c)
        let testInputs = [
            "a": [String(Int(input.latitude * 100) % 100)], // Use lat as 'a'
            "b": [String(Int(input.longitude * 100) % 100)]  // Use lon as 'b'
        ]
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let generateProofResult = try generateCircomProof(
                zkeyPath: zkeyPath,
                circuitInputs: testInputs,
                proofLib: ProofLib.arkworks
            )
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let proofTime = endTime - startTime
            
            print("✅ Test ZK Proof (multiplier2) generated in \(String(format: "%.3f", proofTime))s")
            
            return ZKProofResult(
                proof: generateProofResult.proof,
                publicSignals: generateProofResult.inputs,
                isValid: true
            )
            
        } catch {
            print("❌ Test ZK Proof generation failed: \(error)")
            throw ZKProofError.proofGenerationFailed(error)
        }
        */
        
        // MARK: - Temporary Mock Implementation
        // Remove this once you have real ZKMoPro integration
        
        // Simulate proof generation time
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Create a mock proof for demonstration
        let mockProof = generateMockProof(input: input)
        
        print("🔄 Mock ZK Proof generated for location privacy")
        print("   Radius: \(LocationService.formatDistance(input.radiusKm))")
        print("   Center: \(LocationService.formatApproximateCoordinate(input.centerLatitude)), \(LocationService.formatApproximateCoordinate(input.centerLongitude))")
        print("   💡 To use real ZK proofs, add MoproFFI package and uncomment integration code above")
        
        return mockProof
    }
    
    /// Verify a ZK proof using ZKMoPro Swift Package
    func verifyLocationProof(_ locationProof: LocationProof) async -> Bool {
        do {
            // MARK: - Real ZKMoPro Verification
            // Uncomment once you have MoproFFI package integrated:
            
            /*
            let isValid = try verifyCircomProof(
                proof: locationProof.proof,
                publicSignals: locationProof.publicSignals,
                proofLib: ProofLib.arkworks
            )
            
            print("🔍 ZK Proof verification result: \(isValid ? "✅ Valid" : "❌ Invalid")")
            return isValid
            */
            
            // MARK: - Temporary Mock Verification
            // Remove this once you have real ZKMoPro integration
            
            // Simulate verification time
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Mock verification - in reality this would verify the cryptographic proof
            let isValid = !locationProof.proof.isEmpty && !locationProof.publicSignals.isEmpty
            
            print("🔍 Mock ZK Proof verification: \(isValid ? "✅ Valid" : "❌ Invalid")")
            print("   💡 To use real verification, add MoproFFI package and uncomment integration code above")
            
            return isValid
            
        } catch {
            print("❌ ZK Proof verification failed: \(error)")
            return false
        }
    }
    
    // MARK: - Demo Function for Testing ZKMoPro Integration
    
    /// Test the ZKMoPro integration with the default multiplier2 circuit
    func testZKMoproIntegration() async -> Bool {
        /*
        // Uncomment this once you have MoproFFI package and multiplier2_final.zkey file:
        
        guard let zkeyPath = Bundle.main.path(forResource: defaultCircuitName, ofType: "zkey") else {
            print("❌ multiplier2_final.zkey not found in bundle")
            return false
        }
        
        let testInputs = [
            "a": ["3"],
            "b": ["5"]
        ]
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let result = try generateCircomProof(
                zkeyPath: zkeyPath,
                circuitInputs: testInputs,
                proofLib: ProofLib.arkworks
            )
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let proofTime = endTime - startTime
            
            print("✅ ZKMoPro integration test successful!")
            print("   Proof generated in \(String(format: "%.3f", proofTime))s")
            print("   Proof: \(result.proof.prefix(50))...")
            
            // Test verification
            let isValid = try verifyCircomProof(
                proof: result.proof,
                publicSignals: result.inputs,
                proofLib: ProofLib.arkworks
            )
            
            print("   Verification: \(isValid ? "✅ Valid" : "❌ Invalid")")
            return isValid
            
        } catch {
            print("❌ ZKMoPro integration test failed: \(error)")
            return false
        }
        */
        
        // Mock test for now
        print("🔄 Mock ZKMoPro integration test")
        print("   💡 Uncomment real test code once MoproFFI package is added")
        return true
    }
    
    // MARK: - Mock Implementation (Remove when using real ZKMoPro)
    
    private func generateMockProof(input: ZKProofInput) -> ZKProofResult {
        // Create a deterministic but fake proof based on inputs
        let proofData = [
            String(input.timestamp),
            String(Int(input.radiusKm * 1000)),
            String(Int(input.centerLatitude * 1000000)),
            String(Int(input.centerLongitude * 1000000))
        ].joined(separator: "_")
        
        let mockProof = "mock_proof_\(proofData.hash)"
        
        // Public signals typically include non-sensitive information
        let publicSignals = [
            String(Int(input.centerLatitude * 1000000)), // Approximate center latitude
            String(Int(input.centerLongitude * 1000000)), // Approximate center longitude
            String(Int(input.radiusKm * 1000)), // Radius in meters
            String(input.timestamp), // Timestamp
            "1" // Proof validity flag
        ]
        
        return ZKProofResult(
            proof: mockProof,
            publicSignals: publicSignals,
            isValid: true
        )
    }
    
    // MARK: - Utility Methods
    
    /// Create a location proof from current location
    func createLocationProofFromCurrentLocation(radiusKm: Double) async throws -> LocationProof {
        let currentLocation = try await locationService.getCurrentLocation()
        let approximateLocation = try await locationService.getApproximateLocation(for: currentLocation.coordinate)
        
        // Suggest an approximate center that obscures the exact location
        let approximateCenter = locationService.suggestApproximateCenter(
            for: currentLocation.coordinate,
            radiusKm: radiusKm
        )
        
        // Generate the ZK proof
        let proofResult = await generateLocationProof(
            actualLocation: currentLocation.coordinate,
            approximateCenter: approximateCenter,
            radiusKm: radiusKm
        )
        
        guard proofResult.isValid else {
            throw ZKProofError.proofGenerationFailed(nil)
        }
        
        return LocationProof(
            proof: proofResult.proof,
            publicSignals: proofResult.publicSignals,
            radiusKm: radiusKm,
            centerPoint: ApproximateLocation(from: approximateCenter, cityName: approximateLocation.cityName, countryName: approximateLocation.countryName)
        )
    }
    
    /// Batch verify multiple location proofs
    func verifyLocationProofs(_ proofs: [LocationProof]) async -> [Bool] {
        var results: [Bool] = []
        
        for proof in proofs {
            let isValid = await verifyLocationProof(proof)
            results.append(isValid)
        }
        
        return results
    }
}

// MARK: - ZKProofError
enum ZKProofError: Error, LocalizedError {
    case circuitNotFound
    case locationOutsideRadius
    case proofGenerationFailed(Error?)
    case proofVerificationFailed(Error?)
    case invalidInput
    case moproPackageNotIntegrated
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .circuitNotFound:
            return "ZK circuit file not found. Please ensure the .zkey file is included in your project bundle."
        case .locationOutsideRadius:
            return "The actual location is outside the specified radius."
        case .proofGenerationFailed(let error):
            return "Failed to generate ZK proof: \(error?.localizedDescription ?? "Unknown error")"
        case .proofVerificationFailed(let error):
            return "Failed to verify ZK proof: \(error?.localizedDescription ?? "Unknown error")"
        case .invalidInput:
            return "Invalid input parameters for ZK proof generation."
        case .moproPackageNotIntegrated:
            return "MoproFFI package not integrated. Please add the ZKMoPro Swift Package to your project."
        case .unknown(let error):
            return "Unknown ZK proof error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .circuitNotFound:
            return "Add the ZK circuit (.zkey) file to your Xcode project bundle resources."
        case .locationOutsideRadius:
            return "Choose a larger radius or adjust the approximate center location."
        case .proofGenerationFailed, .proofVerificationFailed:
            return "Check that MoproFFI is properly integrated and try again."
        case .invalidInput:
            return "Verify that all location coordinates and radius values are valid."
        case .moproPackageNotIntegrated:
            return "Add https://github.com/zkmopro/mopro-swift-package as a package dependency in Xcode."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}

// MARK: - String Extension for Hashing
extension String {
    var hash: String {
        return String(self.hashValue)
    }
}

// MARK: - Proof Storage Service
/// Service for persisting ZK proofs locally
/// This demonstrates how to add persistent storage to your app
class ProofStorageService: ObservableObject {
    @Published var storedProofs: [LocationProof] = []
    
    private let userDefaults = UserDefaults.standard
    private let proofsKey = "stored_location_proofs"
    
    init() {
        loadStoredProofs()
    }
    
    // MARK: - Persistence Methods
    
    /// Save a location proof to persistent storage
    func saveLocationProof(_ proof: LocationProof) {
        // Add to in-memory array
        if let index = storedProofs.firstIndex(where: { $0.id == proof.id }) {
            storedProofs[index] = proof
        } else {
            storedProofs.append(proof)
        }
        
        // Persist to UserDefaults
        saveToUserDefaults()
        
        print("💾 Saved location proof: \(proof.id)")
        print("   Radius: \(LocationService.formatDistance(proof.radiusKm))")
        print("   Location: \(proof.centerPoint.cityName)")
    }
    
    /// Load all stored proofs from persistent storage
    func loadStoredProofs() {
        guard let data = userDefaults.data(forKey: proofsKey) else {
            print("📱 No stored proofs found")
            return
        }
        
        do {
            let proofs = try JSONDecoder().decode([LocationProof].self, from: data)
            self.storedProofs = proofs
            print("📱 Loaded \(proofs.count) stored proofs")
        } catch {
            print("❌ Failed to load stored proofs: \(error)")
        }
    }
    
    /// Delete a specific proof
    func deleteProof(_ proofId: String) {
        storedProofs.removeAll { $0.id == proofId }
        saveToUserDefaults()
        print("🗑️ Deleted proof: \(proofId)")
    }
    
    /// Clear all stored proofs
    func clearAllProofs() {
        storedProofs.removeAll()
        userDefaults.removeObject(forKey: proofsKey)
        print("🧹 Cleared all stored proofs")
    }
    
    /// Get proofs for a specific location
    func getProofsNear(location: CLLocationCoordinate2D, radiusKm: Double) -> [LocationProof] {
        return storedProofs.filter { proof in
            let proofCenter = CLLocationCoordinate2D(
                latitude: proof.centerPoint.latitude,
                longitude: proof.centerPoint.longitude
            )
            return location.isWithinRadius(radiusKm, of: proofCenter)
        }
    }
    
    /// Get proofs by date range
    func getProofs(from startDate: Date, to endDate: Date) -> [LocationProof] {
        return storedProofs.filter { proof in
            proof.timestamp >= startDate && proof.timestamp <= endDate
        }
    }
    
    /// Get proof statistics
    func getProofStatistics() -> ProofStatistics {
        let totalProofs = storedProofs.count
        let verifiedProofs = storedProofs.filter { $0.isVerified }.count
        let averageRadius = storedProofs.isEmpty ? 0 : storedProofs.map { $0.radiusKm }.reduce(0, +) / Double(totalProofs)
        
        return ProofStatistics(
            totalProofs: totalProofs,
            verifiedProofs: verifiedProofs,
            averageRadius: averageRadius,
            oldestProof: storedProofs.min { $0.timestamp < $1.timestamp }?.timestamp,
            newestProof: storedProofs.max { $0.timestamp < $1.timestamp }?.timestamp
        )
    }
    
    // MARK: - Private Methods
    
    private func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(storedProofs)
            userDefaults.set(data, forKey: proofsKey)
        } catch {
            print("❌ Failed to save proofs: \(error)")
        }
    }
}

// MARK: - Proof Statistics
struct ProofStatistics {
    let totalProofs: Int
    let verifiedProofs: Int
    let averageRadius: Double
    let oldestProof: Date?
    let newestProof: Date?
    
    var verificationRate: Double {
        return totalProofs > 0 ? Double(verifiedProofs) / Double(totalProofs) : 0
    }
}

// MARK: - Advanced Storage Options
/// Example of how to implement Core Data storage for production apps
/*
import CoreData

class CoreDataProofStorage: ObservableObject {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LocationProofs")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveLocationProof(_ proof: LocationProof) {
        // Create Core Data entity
        let entity = LocationProofEntity(context: context)
        entity.id = proof.id
        entity.proof = proof.proof
        entity.publicSignals = proof.publicSignals.joined(separator: ",")
        entity.radiusKm = proof.radiusKm
        entity.timestamp = proof.timestamp
        entity.isVerified = proof.isVerified
        
        // Save context
        do {
            try context.save()
            print("💾 Saved proof to Core Data")
        } catch {
            print("❌ Core Data save error: \(error)")
        }
    }
}
*/

// MARK: - Network Storage Options
/// Example of how to sync proofs with a backend API
/*
class NetworkProofStorage: ObservableObject {
    private let apiBaseURL = "https://api.fairbnb.com"
    
    func uploadLocationProof(_ proof: LocationProof) async throws {
        let url = URL(string: "\(apiBaseURL)/proofs")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(proof)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200 {
            print("☁️ Uploaded proof to server")
        } else {
            throw NetworkError.uploadFailed
        }
    }
    
    func downloadLocationProofs() async throws -> [LocationProof] {
        let url = URL(string: "\(apiBaseURL)/proofs")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let proofs = try decoder.decode([LocationProof].self, from: data)
        
        print("☁️ Downloaded \(proofs.count) proofs from server")
        return proofs
    }
}

enum NetworkError: Error {
    case uploadFailed
    case downloadFailed
}
*/ 
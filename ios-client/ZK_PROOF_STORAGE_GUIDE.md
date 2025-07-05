# 📍 ZK Proof Storage & Usage Guide

## Overview

This guide explains how Zero-Knowledge (ZK) location proofs are stored, managed, and used throughout the FairBnB iOS app.

## 🏗️ Current Storage Architecture

### 1. **In-Memory Storage (Current)**
```swift
class ZKProofService: ObservableObject {
    @Published var lastProofResult: ZKProofResult?  // Latest proof
    @Published var proofError: ZKProofError?        // Error state
}
```

**Characteristics:**
- ✅ Fast access and updates
- ✅ Automatic UI updates via `@Published`
- ❌ Lost when app closes
- ❌ No persistence between sessions

### 2. **Model-Embedded Storage**
```swift
struct Property {
    let locationProof: LocationProof     // Property location proof
    let images: [PropertyImage]          // Each image can have proof
}

struct PropertyImage {
    let locationProof: LocationProof?    // Optional image location proof
}
```

**Characteristics:**
- ✅ Structured data organization
- ✅ Type-safe proof handling
- ✅ Codable for serialization
- ❌ Currently not persisted

## 📱 How Proofs Are Used

### **1. Property Listings**

#### **Generation:**
```swift
// When creating a property listing
let proofResult = await zkProofService.generateLocationProof(
    actualLocation: actualCoordinate,
    approximateCenter: approximateCenter,
    radiusKm: selectedRadius
)

let locationProof = LocationProof(
    proof: proofResult.proof,
    publicSignals: proofResult.publicSignals,
    radiusKm: selectedRadius,
    centerPoint: approximateLocation
)
```

#### **Display:**
```swift
// In search results
Text(property.displayLocation)  // "Within 2km of Downtown"

// Privacy radius indicator
Text("Privacy radius: \(LocationService.formatDistance(property.locationProof.radiusKm))")
```

#### **Verification:**
```swift
// When user taps "Verify Location"
let isValid = await zkProofService.verifyLocationProof(property.locationProof)
```

### **2. Photo Verification**

#### **Camera Integration:**
```swift
// When taking a photo
let capturedImage = await cameraService.capturePhoto()
// Automatically generates location proof for the image
```

#### **Proof Display:**
```swift
// In image gallery
if let locationProof = image.locationProof {
    Text("Photo verified within \(LocationService.formatDistance(locationProof.radiusKm))")
}
```

### **3. Privacy Controls**

#### **User Settings:**
```swift
struct LocationPrivacySettings {
    var defaultRadiusKm: Double = 1.0        // Default privacy radius
    var requireLocationProof: Bool = true     // Require proofs for listings
    var maxRadiusKm: Double = 5.0            // Maximum allowed radius
}
```

#### **Radius Selection:**
```swift
// Privacy radius picker
Slider(value: $selectedRadius, in: 0.5...5.0, step: 0.5)
```

## 💾 Storage Options

### **Option 1: UserDefaults (Simple)**
```swift
class ProofStorageService: ObservableObject {
    @Published var storedProofs: [LocationProof] = []
    
    func saveLocationProof(_ proof: LocationProof) {
        storedProofs.append(proof)
        // Save to UserDefaults
        let data = try JSONEncoder().encode(storedProofs)
        UserDefaults.standard.set(data, forKey: "stored_proofs")
    }
}
```

**Best for:**
- ✅ Simple proof storage
- ✅ User preferences
- ✅ Small amounts of data
- ❌ Not suitable for large datasets

### **Option 2: Core Data (Advanced)**
```swift
class CoreDataProofStorage: ObservableObject {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LocationProofs")
        // ... configuration
        return container
    }()
    
    func saveLocationProof(_ proof: LocationProof) {
        let entity = LocationProofEntity(context: context)
        entity.id = proof.id
        entity.proof = proof.proof
        // ... set other properties
        try context.save()
    }
}
```

**Best for:**
- ✅ Large datasets
- ✅ Complex queries
- ✅ Relationships between data
- ✅ Background processing

### **Option 3: Network Storage (Production)**
```swift
class NetworkProofStorage: ObservableObject {
    func uploadLocationProof(_ proof: LocationProof) async throws {
        let url = URL(string: "https://api.fairbnb.com/proofs")!
        // ... upload logic
    }
    
    func downloadLocationProofs() async throws -> [LocationProof] {
        // ... download logic
    }
}
```

**Best for:**
- ✅ Multi-device sync
- ✅ Backup and recovery
- ✅ Sharing between users
- ✅ Analytics and insights

## 🔄 Proof Lifecycle

### **1. Generation Flow**
```
User Action → Location Capture → ZK Proof Generation → Storage → UI Update
```

**Example:**
```swift
// 1. User takes photo
let image = await cameraService.capturePhoto()

// 2. Get location
let location = await locationService.getCurrentLocation()

// 3. Generate proof
let proof = await zkProofService.generateLocationProof(...)

// 4. Store in image
let propertyImage = PropertyImage(imageData: image, locationProof: proof)

// 5. UI updates automatically via @Published
```

### **2. Verification Flow**
```
User Request → Proof Retrieval → ZK Verification → Result Display
```

**Example:**
```swift
// 1. User taps "Verify"
Button("Verify Location") {
    // 2. Get proof from property
    let proof = property.locationProof
    
    // 3. Verify proof
    Task {
        let isValid = await zkProofService.verifyLocationProof(proof)
        // 4. Update UI
        showVerificationResult(isValid)
    }
}
```

## 🛠️ Implementation Examples

### **Adding Persistent Storage**

1. **Create Storage Service:**
```swift
class ProofStorageService: ObservableObject {
    @Published var storedProofs: [LocationProof] = []
    
    func saveLocationProof(_ proof: LocationProof) {
        // Implementation in ZKProofService.swift
    }
}
```

2. **Integrate with App:**
```swift
@main
struct FairbnbApp: App {
    let proofStorage = ProofStorageService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(proofStorage)
        }
    }
}
```

3. **Use in Views:**
```swift
struct ProfileView: View {
    @EnvironmentObject var proofStorage: ProofStorageService
    
    var body: some View {
        List(proofStorage.storedProofs) { proof in
            ProofRowView(proof: proof)
        }
    }
}
```

### **Proof Management Features**

#### **Proof History:**
```swift
// Get all proofs for a user
let allProofs = proofStorage.storedProofs

// Get proofs by date range
let recentProofs = proofStorage.getProofs(
    from: Date().addingTimeInterval(-7*24*60*60),  // Last 7 days
    to: Date()
)
```

#### **Location-Based Queries:**
```swift
// Find proofs near a location
let nearbyProofs = proofStorage.getProofsNear(
    location: userLocation,
    radiusKm: 5.0
)
```

#### **Statistics:**
```swift
let stats = proofStorage.getProofStatistics()
print("Total proofs: \(stats.totalProofs)")
print("Verification rate: \(stats.verificationRate * 100)%")
```

## 🔐 Security Considerations

### **Proof Integrity**
- ✅ Proofs are cryptographically signed
- ✅ Tampering is detectable
- ✅ Public signals are verifiable

### **Privacy Protection**
- ✅ Exact locations never stored
- ✅ Only approximate coordinates saved
- ✅ User controls privacy radius

### **Data Protection**
```swift
// Encrypt sensitive data before storage
func encryptProof(_ proof: LocationProof) -> Data {
    // Use iOS Keychain or CryptoKit
    // Implementation depends on security requirements
}
```

## 📊 Usage Analytics

### **Proof Metrics**
```swift
struct ProofMetrics {
    let generationTime: TimeInterval
    let verificationTime: TimeInterval
    let proofSize: Int
    let privacyRadius: Double
}
```

### **User Behavior**
```swift
// Track proof usage patterns
func trackProofGeneration(radius: Double, location: String) {
    // Analytics implementation
}
```

## 🚀 Production Recommendations

### **For MVP:**
1. **Use UserDefaults** for simple proof storage
2. **Implement basic proof history**
3. **Add proof verification UI**

### **For Scale:**
1. **Migrate to Core Data** for complex queries
2. **Add network sync** for multi-device support
3. **Implement proof caching** for performance

### **For Enterprise:**
1. **Use dedicated backend** for proof storage
2. **Add proof auditing** and compliance
3. **Implement proof analytics** dashboard

## 🧪 Testing Strategies

### **Unit Tests:**
```swift
func testProofStorage() {
    let storage = ProofStorageService()
    let proof = LocationProof(...)
    
    storage.saveLocationProof(proof)
    
    XCTAssertTrue(storage.storedProofs.contains { $0.id == proof.id })
}
```

### **Integration Tests:**
```swift
func testProofGeneration() async {
    let service = ZKProofService(locationService: locationService)
    let result = await service.generateLocationProof(...)
    
    XCTAssertTrue(result.isValid)
    XCTAssertFalse(result.proof.isEmpty)
}
```

### **UI Tests:**
```swift
func testProofVerification() {
    let app = XCUIApplication()
    app.buttons["Verify Location"].tap()
    
    // Wait for verification to complete
    let verificationResult = app.staticTexts["Verification Result"]
    XCTAssertTrue(verificationResult.waitForExistence(timeout: 5))
}
```

## 📚 Next Steps

1. **Choose Storage Strategy** based on your needs
2. **Implement Persistence** using provided examples
3. **Add Proof Management UI** for user control
4. **Test Thoroughly** with real ZK proofs
5. **Monitor Performance** and optimize as needed

## 🤝 Need Help?

- Check the [ZKMoPro Documentation](https://zkmopro.org/docs)
- Review the implementation in `ZKProofService.swift`
- Test with the "Test ZKMoPro" button in the app
- Use the provided `ProofStorageService` as a starting point 
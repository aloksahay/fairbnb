# FairBnB iOS App

A privacy-first home sharing iOS application built with SwiftUI that uses Zero-Knowledge proofs to protect location privacy while enabling trust and verification.

## Features

### 🏠 Core Functionality
- **Property Listings**: Create and browse property listings
- **Location Privacy**: Use ZK proofs to verify location without revealing exact coordinates
- **Photo Verification**: Take photos with location proofs for property verification
- **Search & Discovery**: Find properties with privacy-preserving location filters

### 🔒 Privacy Features
- **Zero-Knowledge Location Proofs**: Prove you're within a radius without revealing exact location
- **Configurable Privacy Radius**: Choose from 0.5km to 5km privacy zones
- **Approximate Location Display**: Show general area instead of exact coordinates
- **Location Proof Verification**: Verify others' location claims cryptographically

### 📱 Technical Features
- **SwiftUI Interface**: Modern, native iOS experience
- **Camera Integration**: Capture photos with location metadata
- **Core Location**: GPS coordinate access with privacy controls
- **ZKMoPro Ready**: Structured for easy ZK proof integration

## Architecture

```
ios-client/Fairbnb/Fairbnb/
├── FairbnbApp.swift          # Main app entry point
├── ContentView.swift         # Tab-based main interface
├── Models.swift              # Data models for properties, proofs, users
├── LocationService.swift     # GPS and location privacy management
├── CameraService.swift       # Photo capture with location verification
├── ZKProofService.swift      # Zero-knowledge proof generation/verification
├── SearchView.swift          # Property search with privacy filters
├── HostView.swift           # Multi-step property listing creation
└── ProfileView.swift        # User profile and privacy settings
```

## ZKMoPro Integration

This app is structured to work with [ZKMoPro](https://zkmopro.org/) for generating zero-knowledge proofs. Currently, it includes mock implementations that demonstrate the UX flow.

### To Complete ZKMoPro Integration:

#### 1. Set Up ZKMoPro Build Environment

Follow the [ZKMoPro Getting Started guide](https://zkmopro.org/docs/setup/getting-started) to:
- Install Rust and required dependencies
- Run `mopro init` to create your project
- Select iOS platform during setup
- Run `mopro build` to generate iOS bindings

#### 2. Add ZKMoPro Bindings to Xcode

After running `mopro build`, you'll have a `MoproiOSBindings` folder containing:
- `mopro.swift` - Swift bindings
- `MoproBindings.xcframework` - Compiled framework

**Add these to your Xcode project:**
1. Drag the `MoproiOSBindings` folder into your Xcode project
2. Ensure both files are added to your target
3. Add the framework to "Frameworks, Libraries, and Embedded Content"

#### 3. Create Location Proof Circuit

You'll need a Circom circuit that proves location within a radius. Example circuit structure:

```javascript
pragma circom 2.0.0;

template LocationProof() {
    signal input lat;           // Actual latitude (private)
    signal input lon;           // Actual longitude (private)
    signal input center_lat;    // Center latitude (public)
    signal input center_lon;    // Center longitude (public)
    signal input radius_km;     // Radius in km (public)
    signal input timestamp;     // Timestamp (public)
    
    signal output valid;        // 1 if within radius, 0 otherwise
    
    // Circuit logic to verify distance <= radius
    // Implementation details depend on your specific requirements
}
```

#### 4. Add Circuit Files to Xcode

1. Compile your circuit to generate `.zkey` file
2. Add the `.zkey` file to your Xcode project bundle resources
3. Go to Build Phases → Copy Bundle Resources
4. Add your `.zkey` file to ensure it's included in the app bundle

#### 5. Enable Real ZK Proof Generation

In `ZKProofService.swift`, uncomment and modify the ZKMoPro integration code:

```swift
import moproFFI  // Add this import

// In generateZKProof method, replace mock implementation with:
do {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    let generateProofResult = try generateCircomProof(
        zkeyPath: zkeyPath,
        circuitInputs: zkInputs,
        proofLib: ProofLib.arkworks
    )
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let proofTime = endTime - startTime
    
    print("✅ ZK Proof generated in \(String(format: "%.3f", proofTime))s")
    
    return ZKProofResult(
        proof: generateProofResult.proof,
        publicSignals: generateProofResult.inputs,
        isValid: true
    )
} catch {
    throw ZKProofError.proofGenerationFailed(error)
}
```

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 15.0+
- Swift 5.9+

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd fairbnb/ios-client
   ```

2. **Open in Xcode**
   ```bash
   open Fairbnb/Fairbnb.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press Cmd+R to build and run

### Permissions Required

The app requires the following permissions:
- **Location Access**: For generating location proofs
- **Camera Access**: For taking property photos with location verification
- **Photo Library**: For selecting existing photos

These permissions are requested automatically when needed.

## Usage

### For Guests

1. **Search Properties**
   - Browse properties with privacy-preserving locations
   - See general area without exact addresses
   - Verify location proofs to ensure authenticity

2. **Location Privacy**
   - Properties show approximate locations only
   - ZK proofs verify claims without revealing exact coordinates
   - Choose search radius for finding nearby properties

### For Hosts

1. **Create Listings**
   - 4-step process: Basic Info → Location Proof → Photos → Amenities
   - Generate ZK proof of your property location
   - Take photos with location verification
   - Set privacy radius (0.5km - 5km)

2. **Privacy Controls**
   - Choose how much location privacy you want
   - Generate cryptographic proofs of location
   - Verify your property is in claimed area without revealing exact address

## Key Components

### LocationService
Manages GPS access and location privacy:
- Requests location permissions
- Provides approximate coordinates
- Suggests privacy-preserving center points
- Formats location data for display

### ZKProofService
Handles zero-knowledge proof generation and verification:
- Creates location proofs with configurable radius
- Verifies existing proofs
- Manages proof generation state
- Provides mock implementation for development

### CameraService
Integrates camera with location verification:
- Captures photos with location metadata
- Generates location proofs for images
- Handles camera permissions
- Processes photo library selections

## Configuration

### Privacy Settings
Users can configure:
- Default privacy radius (0.5km - 5km)
- Maximum allowed radius
- Whether to require location proofs
- Whether to allow exact location sharing

### ZK Circuit Settings
In `ZKProofService.swift`:
- `circuitName`: Name of your circuit file
- `zkeyFileName`: Name of your .zkey file

## Testing

### Mock Mode
The app includes comprehensive mock implementations that demonstrate:
- ZK proof generation flow (2-second simulation)
- Proof verification (0.5-second simulation)
- Sample property data with location proofs
- Location privacy features

### Real Testing
Once ZKMoPro is integrated:
- Test proof generation with real coordinates
- Verify proof validation works correctly
- Test with different privacy radius settings
- Validate circuit constraints

## Troubleshooting

### Common Issues

1. **Location Permission Denied**
   - Guide users to Settings → Privacy & Security → Location Services
   - Provide clear error messages and recovery suggestions

2. **Camera Permission Denied**
   - Direct users to Settings → Privacy & Security → Camera
   - Offer alternative photo selection from library

3. **ZK Proof Generation Fails**
   - Ensure .zkey file is in app bundle
   - Check ZKMoPro bindings are properly integrated
   - Verify circuit inputs are correctly formatted

### Debug Information

The app provides extensive logging:
- Location service status and errors
- ZK proof generation timing and results
- Camera service operations
- Privacy setting changes

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [ZKMoPro](https://zkmopro.org/) for zero-knowledge proof infrastructure
- ETHGlobal Cannes 2025 for the hackathon opportunity
- The zero-knowledge and privacy community for inspiration

## Next Steps

To complete the integration:

1. **Implement Real ZK Circuit**: Create a production-ready location proof circuit
2. **Add Backend Integration**: Connect to API for storing/retrieving proofs
3. **Enhanced Map View**: Show approximate locations on interactive maps
4. **Batch Proof Verification**: Efficiently verify multiple location proofs
5. **Advanced Privacy Features**: Add more sophisticated privacy controls
6. **Testing & Security**: Comprehensive testing of ZK proof security

For questions or support, please open an issue or contact the development team. 
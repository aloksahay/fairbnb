# FairBnB iOS App

A privacy-first home sharing app built with SwiftUI, featuring **Privy embedded wallets** for seamless crypto payments and authentication.

## 🚀 Current Features

### ✅ Privy Authentication & Wallet Integration
- **Email OTP Authentication** - Secure login with email verification
- **Embedded Wallet Creation** - Self-custodial wallets created automatically
- **Wallet Management** - Send, receive, and manage crypto payments
- **Mock Implementation** - Fully functional demo without real API calls

### 🎯 App Structure (Simplified)
- **Login Screen** - Clean onboarding with feature highlights
- **Dashboard** - Authenticated user home with wallet overview
- **Wallet Management** - Complete wallet interface with transaction flows
- **Status Monitoring** - Real-time app feature status

## 📱 Screenshots & Flow

### Authentication Flow
1. **Welcome Screen** - Feature overview and sign-in prompt
2. **Email Login** - OTP verification with automatic wallet creation
3. **Dashboard** - Personalized home with wallet status
4. **Wallet Interface** - Full wallet management capabilities

## 🛠 Technical Implementation

### Core Services
- **PrivyAuthService** - Authentication and wallet management
- **EmailLoginView** - Complete OTP authentication flow
- **WalletView** - Comprehensive wallet interface
- **ContentView** - Simplified app structure with authentication state

### Architecture
- **SwiftUI** - Modern iOS interface framework
- **Combine** - Reactive programming for state management
- **Privy SDK** - Embedded wallet and authentication infrastructure
- **Mock Services** - Immediate testing without external dependencies

## 🔧 Setup & Installation

### Prerequisites
- **iOS 18.4+** - Latest iOS version required
- **Xcode 16+** - Latest development environment
- **Swift 5.9+** - Modern Swift language features

### Quick Start
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd fairbnb/ios-client/Fairbnb
   ```

2. **Open in Xcode**
   ```bash
   open Fairbnb.xcodeproj
   ```

3. **Build and Run**
   - Select iOS Simulator (iPhone 16 recommended)
   - Press `Cmd+R` to build and run

### Privy Configuration
1. **Create Privy Account** at [privy.io](https://privy.io)
2. **Get App ID** from Privy Dashboard
3. **Update Configuration** in `PrivyAuthService.swift`:
   ```swift
   private let privyAppId = "YOUR_PRIVY_APP_ID"
   private let privyAppClientId = "YOUR_APP_CLIENT_ID"
   ```

## 🎮 Demo Features

### Mock Authentication
- **Email OTP Flow** - Simulated with 2-second delays
- **Wallet Creation** - Automatic embedded wallet setup
- **Error Handling** - Comprehensive error states and recovery

### Wallet Operations
- **Balance Display** - Mock ETH balance management
- **Send Tokens** - Complete send transaction flow
- **Receive Tokens** - QR code and address sharing
- **Transaction History** - Mock transaction records

## 🔮 Future Enhancements

### Planned Features
- **Zero-Knowledge Location Proofs** - Privacy-preserving location sharing
- **Property Search & Booking** - Crypto-powered home sharing
- **Advanced Privacy Controls** - Customizable location privacy settings
- **Multi-Chain Support** - Support for multiple blockchain networks

### Technical Roadmap
- **Real Privy Integration** - Replace mock services with live API
- **Location Services** - Privacy-first location proof system
- **Property Management** - Complete booking and hosting features
- **Advanced Wallet Features** - DeFi integrations and multi-asset support

## 🛡 Security Features

### Current Implementation
- **Self-Custodial Wallets** - Users control their private keys
- **Secure Authentication** - Email OTP with automatic wallet creation
- **Error Recovery** - Comprehensive error handling and user guidance
- **Mock Security** - Secure patterns ready for production

### Production Security
- **Hardware Security** - Secure enclave protection
- **Biometric Authentication** - Face ID/Touch ID integration
- **Cloud Recovery** - Secure wallet backup and recovery
- **Multi-Factor Authentication** - Additional security layers

## 📝 Development Notes

### Code Structure
- **Simplified Architecture** - Clean separation of concerns
- **Mock Services** - Immediate testing and development
- **Error Handling** - Comprehensive error states and recovery
- **Modern SwiftUI** - Latest iOS development patterns

### Testing
- **Build Success** ✅ - App compiles and runs successfully
- **Authentication Flow** ✅ - Complete login and wallet creation
- **Wallet Interface** ✅ - Full wallet management capabilities
- **Error Scenarios** ✅ - Proper error handling and recovery

## 🤝 Contributing

### Development Setup
1. **Fork the repository**
2. **Create feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit changes** (`git commit -m 'Add amazing feature'`)
4. **Push to branch** (`git push origin feature/amazing-feature`)
5. **Open Pull Request**

### Code Standards
- **SwiftUI Best Practices** - Modern iOS development patterns
- **Comprehensive Documentation** - Clear code comments and documentation
- **Error Handling** - Proper error states and user guidance
- **Testing** - Unit tests for core functionality

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Privy** - Embedded wallet infrastructure
- **SwiftUI** - Modern iOS interface framework
- **Apple Developer** - iOS development platform

---

**Ready to revolutionize home sharing with privacy-first crypto payments!** 🏠✨ 
# 🏠 Fairbnb - Decentralized Accommodation Platform

A decentralized Airbnb alternative built with **0G Storage** for secure, censorship-resistant property listings and bookings.

## 🏗️ **Project Structure**

```
fairbnb/
├── ios-client/          # iOS mobile application
│   ├── Fairbnb/         # Xcode project
│   ├── README.md        # iOS setup guide
├── backend/             # Node.js API server
│   ├── config/          # Environment configuration
│   ├── controllers/     # API request handlers
│   ├── middleware/      # Custom middleware
│   ├── routes/          # API routes
│   ├── services/        # 0G Storage integration
│   ├── types/           # TypeScript definitions
│   ├── index.ts         # Main server file
│   ├── package.json     # Backend dependencies
│   └── README.md        # Backend documentation
└── README.md            # This file
```

## 🚀 **Quick Start**

### **Backend API Server**
```bash
cd backend
npm install
npm run dev
```
- API runs on http://localhost:3000
- Health check: http://localhost:3000/health
- API docs: http://localhost:3000/api

### **iOS Client**
```bash
cd ios-client
open Fairbnb/Fairbnb.xcodeproj
```
- Build and run in Xcode
- Requires iOS 18.4+ simulator or device
- Includes Privy wallet integration

## 🌟 **Key Features**

### **Decentralized Storage**
- **0G Storage Integration**: Property images stored on 0G network
- **Merkle Proof Verification**: Data integrity guaranteed
- **Content Addressing**: Files identified by cryptographic hash
- **Censorship Resistant**: No single point of failure

### **iOS Mobile App**
- **Privy Wallet Integration**: Embedded wallet for seamless UX
- **Property Browsing**: Search and view accommodations
- **Secure Authentication**: Email + wallet-based login
- **Private Key Export**: Multiple methods for key management

### **Backend API**
- **TypeScript Express.js**: Type-safe server architecture
- **File Upload/Download**: Direct 0G Storage integration
- **Security Features**: Rate limiting, CORS, validation
- **RESTful Design**: Clean API endpoints

## 🔧 **Technology Stack**

### **Blockchain & Storage**
- **0G Storage**: Decentralized file storage network
- **Ethereum Compatible**: EVM-based transactions
- **Privy SDK**: Embedded wallet infrastructure

### **Backend**
- **Node.js + TypeScript**: Server runtime
- **Express.js**: Web framework
- **0G TypeScript SDK**: Storage integration
- **Multer**: File upload handling

### **iOS Frontend**
- **Swift + SwiftUI**: Native iOS development
- **Privy iOS SDK**: Wallet and auth integration
- **WebKit**: Private key export interface

## 📡 **API Endpoints**

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `GET` | `/api` | API documentation |
| `POST` | `/api/files/upload` | Upload single file |
| `POST` | `/api/files/upload-multiple` | Upload multiple files |
| `GET` | `/api/files/:rootHash` | Download file |
| `GET` | `/api/files/:rootHash/info` | Get file info |

## 🔑 **Test Wallet Setup**

For development and testing, you'll need to generate a test wallet:

```bash
cd backend
node test-wallet.js
```

This will generate a new test wallet with:
- A unique address for receiving testnet tokens
- A private key to add to your `.env` file
- Instructions for funding the wallet

⚠️ **Important Security Notes**:
- Never commit private keys to version control
- Use the generated wallet only for testnet development
- Store the private key securely in your local `.env` file
- Fund your wallet with 0G testnet tokens: https://faucet.0g.ai/

## 🧪 **Testing**

### **Backend Tests**
```bash
cd backend
npm run test        # API health tests
npm run test-wallet # Generate new test wallet
```

### **iOS Tests**
- Build and run in Xcode
- Test Privy authentication
- Test private key export

### **Integration Tests**
```bash
# Start backend
cd backend && npm run dev

# Test file upload
curl -X POST http://localhost:3000/api/files/upload \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@path/to/image.jpg'
```

## 🔜 **Development Roadmap**

### **Phase 1: Core Infrastructure** ✅
- [x] 0G Storage integration
- [x] iOS app with Privy wallet
- [x] Backend API server
- [x] File upload/download

### **Phase 2: Property Management**
- [ ] Property listing creation
- [ ] Image gallery management
- [ ] Location and amenities
- [ ] Pricing and availability

### **Phase 3: Booking System**
- [ ] Booking requests
- [ ] Payment integration
- [ ] Smart contracts
- [ ] Reputation system

### **Phase 4: Advanced Features**
- [ ] Search and filters
- [ ] Reviews and ratings
- [ ] Host dashboard
- [ ] Guest messaging

## 🌐 **Resources**

- **0G Storage**: https://docs.0g.ai/developer-hub/building-on-0g/storage/sdk
- **Privy Documentation**: https://docs.privy.io/
- **0G Testnet Faucet**: https://faucet.0g.ai/
- **Express.js**: https://expressjs.com/
- **Swift/SwiftUI**: https://developer.apple.com/swift/

## 🔧 **Environment Setup**

1. **Clone Repository**
```bash
git clone <repository-url>
cd fairbnb
```

2. **Backend Setup**
```bash
cd backend
npm install
cp env.example .env
# Edit .env with your configuration
npm run dev
```

3. **iOS Setup**
```bash
cd ios-client
open Fairbnb/Fairbnb.xcodeproj
# Build and run in Xcode
```

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- **0G Labs** for the decentralized storage infrastructure
- **Privy** for the embedded wallet SDK
- **Apple** for Swift and iOS development tools

---

**Built with ❤️ for a decentralized future**

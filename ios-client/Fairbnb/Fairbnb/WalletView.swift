import SwiftUI

struct WalletView: View {
    @ObservedObject var authService: PrivyAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingSendSheet = false
    @State private var showingReceiveSheet = false
    @State private var showingTransactionHistory = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Wallet Header
                    WalletHeaderSection(authService: authService)
                    
                    // Quick Actions
                    QuickActionsSection(
                        showingSendSheet: $showingSendSheet,
                        showingReceiveSheet: $showingReceiveSheet,
                        showingTransactionHistory: $showingTransactionHistory,
                        authService: authService
                    )
                    
                    // Wallet Details
                    WalletDetailsSection(authService: authService)
                    
                    // Security Features
                    SecurityFeaturesSection()
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("My Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await authService.refreshWalletBalance()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(authService.isWalletLoading)
                }
            }
        }
        .sheet(isPresented: $showingSendSheet) {
            SendTokensView(authService: authService)
        }
        .sheet(isPresented: $showingReceiveSheet) {
            ReceiveTokensView(authService: authService)
        }
        .sheet(isPresented: $showingTransactionHistory) {
            TransactionHistoryView(authService: authService)
        }
    }
}

// MARK: - Wallet Header Section

struct WalletHeaderSection: View {
    @ObservedObject var authService: PrivyAuthService
    
    var body: some View {
        VStack(spacing: 16) {
            // Wallet Icon
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            // Balance
            VStack(spacing: 8) {
                if authService.isWalletLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(authService.walletBalance) MNT")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Text("MNT Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Wallet Address
            if let wallet = authService.userWallet {
                VStack(spacing: 8) {
                    Text("Wallet Address")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(wallet.displayAddress)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button(action: {
                            UIPasteboard.general.string = wallet.address
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Error Display
            if let error = authService.walletError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wallet Error")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Text(error.localizedDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    @Binding var showingSendSheet: Bool
    @Binding var showingReceiveSheet: Bool
    @Binding var showingTransactionHistory: Bool
    @ObservedObject var authService: PrivyAuthService
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "arrow.up.circle.fill",
                    title: "Send",
                    color: .blue,
                    action: { showingSendSheet = true }
                )
                
                QuickActionButton(
                    icon: "arrow.down.circle.fill",
                    title: "Receive",
                    color: .green,
                    action: { showingReceiveSheet = true }
                )
                
                QuickActionButton(
                    icon: "clock.arrow.circlepath",
                    title: "History",
                    color: .orange,
                    action: { showingTransactionHistory = true }
                )
                
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Buy",
                    color: .purple,
                    action: { /* TODO: Add buy flow */ }
                )
            }
        }
    }
}



// MARK: - Wallet Details Section

struct WalletDetailsSection: View {
    @ObservedObject var authService: PrivyAuthService
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Wallet Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                if let wallet = authService.userWallet {
                    DetailRow(
                        icon: "network",
                        title: "Network",
                        value: wallet.chainName
                    )
                    
                    DetailRow(
                        icon: "shield.checkered",
                        title: "Type",
                        value: wallet.isEmbedded ? "Embedded Wallet" : "External Wallet"
                    )
                    
                    DetailRow(
                        icon: "calendar",
                        title: "Created",
                        value: DateFormatter.shortDate.string(from: wallet.createdAt)
                    )
                    
                    DetailRow(
                        icon: "key.fill",
                        title: "Custody",
                        value: "Self-Custodial"
                    )
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Security Features Section

struct SecurityFeaturesSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Security Features")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                SecurityFeatureRow(
                    icon: "lock.shield.fill",
                    title: "Self-Custodial",
                    description: "You control your private keys",
                    isEnabled: true
                )
                
                SecurityFeatureRow(
                    icon: "icloud.and.arrow.up.fill",
                    title: "Cloud Recovery",
                    description: "Backup your wallet to iCloud",
                    isEnabled: true
                )
                
                SecurityFeatureRow(
                    icon: "faceid",
                    title: "Biometric Security",
                    description: "Secure transactions with Face ID",
                    isEnabled: true
                )
                
                SecurityFeatureRow(
                    icon: "shield.checkered",
                    title: "Hardware Security",
                    description: "Protected by secure enclaves",
                    isEnabled: true
                )
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
}

struct SecurityFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isEnabled ? .green : .gray)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Send Tokens View

struct SendTokensView: View {
    @ObservedObject var authService: PrivyAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var recipientAddress = ""
    @State private var amount = ""
    @State private var selectedChain = "1" // Ethereum
    @State private var isProcessing = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Send Tokens")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recipient Address")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("0x...", text: $recipientAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount (MNT)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("0", text: $amount)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                        
                        // Send Button
                        Button(action: sendTokens) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                }
                                Text("Send Tokens")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSend ? Color.blue : Color.gray)
                            .cornerRadius(12)
                        }
                        .disabled(!canSend || isProcessing)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Send Tokens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Transaction Sent!", isPresented: $showingSuccess) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Your transaction has been sent successfully!")
        }
    }
    
    private var canSend: Bool {
        !recipientAddress.isEmpty && !amount.isEmpty && Double(amount) != nil
    }
    
    private func sendTokens() {
        isProcessing = true
        
        Task {
            let success = await authService.sendTransaction(
                to: recipientAddress,
                amount: amount,
                chainId: selectedChain
            )
            
            await MainActor.run {
                isProcessing = false
                if success {
                    showingSuccess = true
                }
            }
        }
    }
}

// MARK: - Receive Tokens View

struct ReceiveTokensView: View {
    @ObservedObject var authService: PrivyAuthService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Receive Tokens")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Wallet Address
                    if let wallet = authService.userWallet {
                        VStack(spacing: 16) {
                            Text("Your Wallet Address")
                                .font(.headline)
                            
                            // QR Code Placeholder
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 200, height: 200)
                                .overlay(
                                    VStack {
                                        Image(systemName: "qrcode")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        Text("QR Code")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                            
                            // Address
                            VStack(spacing: 8) {
                                Text(wallet.address)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Button("Copy Address") {
                                    UIPasteboard.general.string = wallet.address
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Instructions
                    VStack(spacing: 12) {
                        Text("How to Receive")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InstructionRow(
                                number: "1",
                                text: "Share your wallet address or QR code"
                            )
                            
                            InstructionRow(
                                number: "2",
                                text: "Sender sends tokens to your address"
                            )
                            
                            InstructionRow(
                                number: "3",
                                text: "Tokens appear in your wallet"
                            )
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Receive Tokens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// MARK: - Transaction History View

struct TransactionHistoryView: View {
    @ObservedObject var authService: PrivyAuthService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Mock transactions
                    ForEach(mockTransactions, id: \.id) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    
                    if mockTransactions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No transactions yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Your transaction history will appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
            .navigationTitle("Transaction History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var mockTransactions: [MockTransaction] {
        // Return empty array for now - will be populated with real data
        return []
    }
}

struct TransactionRow: View {
    let transaction: MockTransaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.type == .sent ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(transaction.type == .sent ? .red : .green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.type == .sent ? "Sent" : "Received")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == .sent ? "-" : "+")\(transaction.amount) MNT")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(transaction.type == .sent ? .red : .green)
                
                Text(transaction.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct MockTransaction {
    let id = UUID()
    let type: TransactionType
    let amount: String
    let date: Date
    let status: TransactionStatus
    
    enum TransactionType {
        case sent, received
    }
    
    enum TransactionStatus: String {
        case pending = "Pending"
        case completed = "Completed"
        case failed = "Failed"
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Preview

struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView(authService: PrivyAuthService.shared)
    }
} 
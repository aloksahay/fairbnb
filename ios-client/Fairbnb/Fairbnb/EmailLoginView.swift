import SwiftUI

struct EmailLoginView: View {
    @ObservedObject var authService: PrivyAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var otpCode = ""
    @State private var showingSuccess = false
    
    @FocusState private var emailFieldFocused: Bool
    @FocusState private var codeFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Welcome to FairBnB")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Sign in with your email to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Authentication Flow
                    VStack(spacing: 20) {
                        switch authService.otpFlowState {
                        case .initial, .error:
                            EmailInputSection(
                                email: $email,
                                authService: authService,
                                emailFieldFocused: $emailFieldFocused
                            )
                            
                        case .sendingCode:
                            SendingCodeSection(email: email)
                            
                        case .awaitingCodeInput:
                            OTPInputSection(
                                email: email,
                                otpCode: $otpCode,
                                authService: authService,
                                codeFieldFocused: $codeFieldFocused
                            )
                            
                        case .submittingCode:
                            VerifyingCodeSection()
                            
                        case .done:
                            SuccessSection(authService: authService)
                        }
                    }
                    
                    // Error Display
                    if let error = authService.authError {
                        ErrorSection(error: error, authService: authService)
                    }
                    
                    // Features Preview
                    if authService.otpFlowState == .initial {
                        FeaturesPreviewSection()
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(authService.isLoading)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !authService.isLoading {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                
                if authService.otpFlowState == .awaitingCodeInput {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Resend") {
                            Task {
                                await authService.sendEmailCode(to: email)
                            }
                        }
                        .disabled(authService.isLoading)
                    }
                }
            }
        }
        .alert("Welcome to FairBnB!", isPresented: $showingSuccess) {
            Button("Get Started") {
                dismiss()
            }
        } message: {
            Text("Your account and wallet have been created successfully!")
        }
        .onChange(of: authService.isAuthenticated) { isAuth in
            if isAuth {
                showingSuccess = true
            }
        }
    }
}

// MARK: - Email Input Section

struct EmailInputSection: View {
    @Binding var email: String
    @ObservedObject var authService: PrivyAuthService
    @FocusState.Binding var emailFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($emailFieldFocused)
                    .onSubmit {
                        if isValidEmail(email) {
                            sendCode()
                        }
                    }
            }
            
            Button(action: sendCode) {
                HStack {
                    if authService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text("Send Verification Code")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidEmail(email) ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isValidEmail(email) || authService.isLoading)
            
            // Email validation hint
            if !email.isEmpty && !isValidEmail(email) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Please enter a valid email address")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .onAppear {
            emailFieldFocused = true
        }
    }
    
    private func sendCode() {
        Task {
            await authService.sendEmailCode(to: email)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - Sending Code Section

struct SendingCodeSection: View {
    let email: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            VStack(spacing: 8) {
                Text("Sending verification code...")
                    .font(.headline)
                
                Text("We're sending a 6-digit code to")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(email)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}

// MARK: - OTP Input Section

struct OTPInputSection: View {
    let email: String
    @Binding var otpCode: String
    @ObservedObject var authService: PrivyAuthService
    @FocusState.Binding var codeFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Check your email")
                    .font(.headline)
                
                Text("We sent a 6-digit code to")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(email)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter 6-digit code", text: $otpCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .focused($codeFieldFocused)
                    .onChange(of: otpCode) { newValue in
                        // Limit to 6 digits
                        let filtered = String(newValue.prefix(6).filter { $0.isNumber })
                        if filtered != newValue {
                            otpCode = filtered
                        }
                        
                        // Auto-submit when 6 digits entered
                        if filtered.count == 6 {
                            verifyCode()
                        }
                    }
            }
            
            Button(action: verifyCode) {
                HStack {
                    if authService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                    }
                    Text("Verify & Sign In")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(otpCode.count == 6 ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(otpCode.count != 6 || authService.isLoading)
            
            // Resend option
            HStack {
                Text("Didn't receive the code?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Resend") {
                    Task {
                        await authService.sendEmailCode(to: email)
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
                .disabled(authService.isLoading)
            }
        }
        .onAppear {
            codeFieldFocused = true
        }
    }
    
    private func verifyCode() {
        Task {
            await authService.verifyEmailCode(otpCode)
        }
    }
}

// MARK: - Verifying Code Section

struct VerifyingCodeSection: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            VStack(spacing: 8) {
                Text("Verifying code...")
                    .font(.headline)
                
                Text("Creating your account and wallet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Success Section

struct SuccessSection: View {
    @ObservedObject var authService: PrivyAuthService
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Welcome!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your account has been created successfully")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let user = authService.currentUser {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text(user.email)
                            .fontWeight(.medium)
                    }
                    
                    if let wallet = authService.userWallet {
                        HStack {
                            Image(systemName: "wallet.pass.fill")
                                .foregroundColor(.purple)
                            Text("Wallet: \(wallet.displayAddress)")
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Error Section

struct ErrorSection: View {
    let error: PrivyAuthError
    @ObservedObject var authService: PrivyAuthService
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Authentication Error")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Button("Try Again") {
                authService.resetAuthFlow()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Features Preview Section

struct FeaturesPreviewSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("What you'll get:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "wallet.pass.fill",
                    title: "Embedded Wallet",
                    description: "Secure self-custodial wallet created automatically"
                )
                
                FeatureRow(
                    icon: "shield.checkered",
                    title: "Privacy Protection",
                    description: "Zero-knowledge proofs protect your location data"
                )
                
                FeatureRow(
                    icon: "house.circle.fill",
                    title: "Property Booking",
                    description: "Book properties with crypto payments"
                )
                
                FeatureRow(
                    icon: "creditcard.fill",
                    title: "Easy Payments",
                    description: "Send and receive payments seamlessly"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}



// MARK: - Preview

struct EmailLoginView_Previews: PreviewProvider {
    static var previews: some View {
        EmailLoginView(authService: PrivyAuthService.shared)
    }
} 
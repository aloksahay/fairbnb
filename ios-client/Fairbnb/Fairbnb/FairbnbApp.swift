//
//  FairbnbApp.swift
//  Fairbnb
//
//  Created by Alok Sahay on 05.07.2025.
//

import SwiftUI

@main
struct FairbnbApp: App {
    @StateObject private var selfVerificationService = SelfVerificationService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(selfVerificationService)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Handle returning from Self verification
        if url.scheme == "fairbnb" && url.host == "self-verification" {
            // Extract verification result from URL
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            
            if let success = queryItems?.first(where: { $0.name == "success" })?.value,
               success == "true" {
                // Verification successful, check status
                selfVerificationService.handleVerificationReturn()
            } else {
                // Verification failed or cancelled
                selfVerificationService.handleVerificationReturn()
            }
        }
    }
}

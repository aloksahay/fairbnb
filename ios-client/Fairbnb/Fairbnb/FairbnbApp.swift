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
        // Self app returns to the app using the configured URL scheme
        if url.scheme == "fairbnb" {
            // Extract verification result from URL
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            
            // Self may return different parameters, so we handle the return generically
            print("Returned from Self app with URL: \(url)")
            
            // Always check verification status when returning from Self
            selfVerificationService.handleVerificationReturn()
        }
    }
}

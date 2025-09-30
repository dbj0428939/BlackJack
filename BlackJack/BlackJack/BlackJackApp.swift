//
//  BlackJackApp.swift
//  BlackJack
//
//  Created by David Johnson on 6/8/25.
//

import SwiftUI
import GoogleMobileAds

@main
struct BlackJackApp: App {
    @StateObject private var gameState = GameState()
    
    init() {
        // Initialize the Google Mobile Ads SDK
        MobileAds.shared.start()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
        }
    }
}

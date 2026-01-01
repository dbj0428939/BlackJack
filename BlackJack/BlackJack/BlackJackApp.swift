//
//  BlackJackApp.swift
//  BlackJack
//
//  Created by David Johnson on 6/8/25.
//

import SwiftUI
import GoogleMobileAds


@main
struct SpadeBetApp: App {
    @StateObject private var gameState: GameState

    init() {
        // Initialize the StateObject wrapper explicitly when providing a custom init
        _gameState = StateObject(wrappedValue: GameState())

        // Initialize Google Mobile Ads SDK and preload an interstitial so it's ready when we reach the threshold
        // Use the SDK's shared instance property and provide a typed completion closure to avoid 'nil' ambiguity.
        MobileAds.shared.start(completionHandler: { _ in })
        InterstitialAdManager.shared.load()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
        }
    }
}

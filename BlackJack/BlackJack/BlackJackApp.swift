//
//  BlackJackApp.swift
//  BlackJack
//
//  Created by David Johnson on 6/8/25.
//

import SwiftUI

@main
struct BlackjackApp: App {
    @StateObject private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
        }
    }
}


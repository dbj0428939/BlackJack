//
//  GameStats.swift
//  BlackJack
//
//  Created by Trae AI on 1/14/25.
//

import Foundation

class GameStats: ObservableObject {
    @Published var playerWins: Int = 0
    @Published var playerLosses: Int = 0
    @Published var playerBusts: Int = 0
    @Published var pushes: Int = 0
    @Published var playerBlackjacks: Int = 0
    @Published var dealerBlackjacks: Int = 0
    
    // Computed properties for easy access
    var totalGames: Int {
        return playerWins + playerLosses + pushes
    }
    
    var winPercentage: Double {
        guard totalGames > 0 else { return 0.0 }
        return Double(playerWins) / Double(totalGames) * 100.0
    }
    
    // Record game outcomes
    func recordPlayerWin() {
        playerWins += 1
    }
    
    func recordPlayerLoss() {
        playerLosses += 1
    }
    
    func recordPlayerBust() {
        playerBusts += 1
        playerLosses += 1 // Bust counts as a loss
    }
    
    func recordPush() {
        pushes += 1
    }
    
    func recordPlayerBlackjack() {
        playerBlackjacks += 1
        playerWins += 1 // Blackjack counts as a win
    }
    
    func recordDealerBlackjack() {
        dealerBlackjacks += 1
        // Don't automatically count as loss - depends on if player also has blackjack
    }
    
    // Reset all statistics
    func resetStats() {
        playerWins = 0
        playerLosses = 0
        playerBusts = 0
        pushes = 0
        playerBlackjacks = 0
        dealerBlackjacks = 0
    }
    
    // Save/Load functionality (using UserDefaults for persistence)
    func saveStats() {
        UserDefaults.standard.set(playerWins, forKey: "playerWins")
        UserDefaults.standard.set(playerLosses, forKey: "playerLosses")
        UserDefaults.standard.set(playerBusts, forKey: "playerBusts")
        UserDefaults.standard.set(pushes, forKey: "pushes")
        UserDefaults.standard.set(playerBlackjacks, forKey: "playerBlackjacks")
        UserDefaults.standard.set(dealerBlackjacks, forKey: "dealerBlackjacks")
    }
    
    func loadStats() {
        playerWins = UserDefaults.standard.integer(forKey: "playerWins")
        playerLosses = UserDefaults.standard.integer(forKey: "playerLosses")
        playerBusts = UserDefaults.standard.integer(forKey: "playerBusts")
        pushes = UserDefaults.standard.integer(forKey: "pushes")
        playerBlackjacks = UserDefaults.standard.integer(forKey: "playerBlackjacks")
        dealerBlackjacks = UserDefaults.standard.integer(forKey: "dealerBlackjacks")
    }
    
    init() {
        loadStats()
    }
}
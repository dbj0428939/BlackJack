import Foundation
import SwiftUI

// All model types (Hand, Deck, GameStats, SplitGameManager, SplitHand, Rank) are defined
// in separate files within the same module and should be automatically available

enum BlackjackGameState {
    case betting
    case offeringInsurance
    case playerTurn
    case dealerTurn
    case gameOver
}

class BlackjackGame: ObservableObject {
    @Published var gameState: BlackjackGameState = .betting {
        didSet {
            // Removed debug print
        }
    }
    @Published private(set) var playerHand = Hand()
    @Published private(set) var dealerHand = Hand()
    @Published private(set) var currentBet: Double = 0
    @Published private(set) var originalBet: Double = 0
    @Published private(set) var resultMessage: String = ""
    @Published private(set) var payout: Double = 0
    @Published private(set) var insuranceResult: Bool? = nil
    @Published private(set) var insuranceMessage: String = ""
    
    public func updateInsuranceMessage(_ message: String) {
        insuranceMessage = message
    }
    @Published var shouldAutoDeal: Bool = false  // New property to trigger auto-dealing
    
    // Game statistics tracking
    @Published var gameStats = GameStats()
    
    // Enhanced split functionality
    @Published public var splitManager = SplitGameManager()
    
    // Legacy split properties for backward compatibility
    @Published public var hands: [Hand] = []  // All player hands
    @Published public var activeHandIndex: Int = 0  // Index of the hand currently being played
    public let maxHands = 4
    public var hasSplit: Bool { 
        return splitManager.hasSplit || hands.count > 1 
    }
    public var splitBets: [Double] = []
    public var splitResults: [String] = []

    private let deck = Deck()

    init() {}

    // Convenience init is not needed anymore if we are hardcoding to single player.
    // But let's keep it for now in case the user wants to re-add multiplayer later.
    // It won't be called from MainMenuView anymore, but doesn't hurt.
    convenience init(playerSeat: Int, activePlayers: Int) {
        self.init()
    }

    func placeBet(_ amount: Double) {
        currentBet = amount
        originalBet = amount
        shouldAutoDeal = false  // Reset flag after bet is placed
        // Don't automatically start the round - wait for explicit deal action
        gameState = .betting
    }
    
    func drawCard() -> Card? {
        let card = deck.draw()
        if card != nil {
            // Play card deal sound
            SoundManager.shared.playCardDeal()
        }
        return card
    }
    
    func drawCardAvoidingSplitOpportunities(for hand: SplitHand) -> Card? {
        // Always avoid split opportunities for split hands (max 2 hands total)
        guard hand.cards.count > 0 else {
            print("DEBUG: Hand is empty, drawing normal card")
            return deck.draw()
        }
        
        print("DEBUG: Drawing card for hand with \(hand.cards.count) cards: \(hand.cards.map { $0.display })")
        
        // Check against all existing cards in the hand
        let existingRanks = hand.cards.map { $0.rank }
        
        // Try to draw a card that won't create a split opportunity
        var attempts = 0
        let maxAttempts = 5 // Reduced attempts since we can't put cards back
        
        while attempts < maxAttempts {
            guard let card = deck.draw() else { 
                // If deck is empty, reshuffle and try again
                deck.reset()
                continue
            }
            
            // Check if this card would create a split opportunity with any existing card
            var wouldCreateSplit = false
            for existingRank in existingRanks {
                if (card.rank == existingRank) || 
                   (existingRank == .ten && card.rank == .jack) ||
                   (existingRank == .ten && card.rank == .queen) ||
                   (existingRank == .ten && card.rank == .king) ||
                   (existingRank == .jack && card.rank == .ten) ||
                   (existingRank == .jack && card.rank == .queen) ||
                   (existingRank == .jack && card.rank == .king) ||
                   (existingRank == .queen && card.rank == .ten) ||
                   (existingRank == .queen && card.rank == .jack) ||
                   (existingRank == .queen && card.rank == .king) ||
                   (existingRank == .king && card.rank == .ten) ||
                   (existingRank == .king && card.rank == .jack) ||
                   (existingRank == .king && card.rank == .queen) {
                    wouldCreateSplit = true
                    break
                }
            }
            
            if !wouldCreateSplit {
                print("DEBUG: Found suitable card: \(card.display)")
                return card
            }
            
            attempts += 1
        }
        
        // If we couldn't find a suitable card after max attempts, just draw normally
        print("DEBUG: Couldn't find suitable card after \(maxAttempts) attempts, drawing any card")
        return deck.draw()
    }
    
    func drawCardForSplitHand(for hand: SplitHand) -> Card? {
        // Special function for split hands that avoids both split opportunities AND 20-value hands
        guard hand.cards.count > 0 else {
            print("DEBUG: Hand is empty, drawing normal card")
            return deck.draw()
        }
        
        print("DEBUG: Drawing card for split hand with \(hand.cards.count) cards: \(hand.cards.map { $0.display })")
        
        // Check against all existing cards in the hand
        let existingRanks = hand.cards.map { $0.rank }
        
        // Try to draw a card that won't create a split opportunity OR a 20-value hand
        var attempts = 0
        let maxAttempts = 10 // More attempts for stricter requirements
        
        while attempts < maxAttempts {
            guard let card = deck.draw() else { 
                // If deck is empty, reshuffle and try again
                deck.reset()
                continue
            }
            
            // Check if this card would create a split opportunity with any existing card
            var wouldCreateSplit = false
            for existingRank in existingRanks {
                if (card.rank == existingRank) || 
                   (existingRank == .ten && card.rank == .jack) ||
                   (existingRank == .ten && card.rank == .queen) ||
                   (existingRank == .ten && card.rank == .king) ||
                   (existingRank == .jack && card.rank == .ten) ||
                   (existingRank == .jack && card.rank == .queen) ||
                   (existingRank == .jack && card.rank == .king) ||
                   (existingRank == .queen && card.rank == .ten) ||
                   (existingRank == .queen && card.rank == .jack) ||
                   (existingRank == .queen && card.rank == .king) ||
                   (existingRank == .king && card.rank == .ten) ||
                   (existingRank == .king && card.rank == .jack) ||
                   (existingRank == .king && card.rank == .queen) {
                    wouldCreateSplit = true
                    break
                }
            }
            
            // Check if this card would create a 20-value hand (face card + 10-value card)
            var wouldCreate20 = false
            for existingRank in existingRanks {
                let existingValue = existingRank.value
                let cardValue = card.rank.value
                
                // Check if existing card is a 10-value card and new card is also 10-value
                if (existingValue == 10 && cardValue == 10) {
                    wouldCreate20 = true
                    break
                }
            }
            
            if !wouldCreateSplit && !wouldCreate20 {
                print("DEBUG: Found suitable card for split hand: \(card.display)")
                return card
            }
            
            attempts += 1
        }
        
        // If we couldn't find a suitable card after max attempts, just draw normally
        print("DEBUG: Couldn't find suitable card for split hand after \(maxAttempts) attempts, drawing any card")
        return deck.draw()
    }
    
    func updateCurrentBet(_ amount: Double) {
        currentBet = amount
    }
    
    func dealCards() {
        startNewRound()
    }

    func startNewRound() {
        // Initialize split manager
        splitManager.reset()
        splitManager.initializeWithSingleHand(bet: currentBet)
        
        // Legacy compatibility
        hands = [Hand()]
        activeHandIndex = 0
        splitBets = [currentBet]
        splitResults = Array(repeating: "", count: maxHands)
        resultMessage = ""
        deck.reset()
        playerHand.clear()
        dealerHand.clear()
        insuranceResult = nil
        insuranceMessage = ""
        shouldAutoDeal = true  // Signal that cards should be dealt automatically
        
        // Clear insurance bet in GameState as well
        // Note: This assumes GameState is accessible here, which it should be through the view

        // Deal initial cards normally
        if let c1 = deck.draw() { 
            playerHand.addCard(c1)
            hands[0].addCard(c1)
            splitManager.hands[0].addCard(c1)
        }
        if let c2 = deck.draw() { 
            playerHand.addCard(c2)
            hands[0].addCard(c2)
            splitManager.hands[0].addCard(c2)
        }
        // Deal dealer cards normally
        if let c1 = deck.draw() { 
            dealerHand.addCard(c1) 
        }
        if let c2 = deck.draw() { 
            dealerHand.addCard(c2) 
        }

        if dealerHand.cards.first?.rank == Rank.ace {
            gameState = .offeringInsurance
        } else if dealerHand.cards.first?.value == 10 || playerHand.isBlackjack {
            // Clear any previous insurance data since no insurance is offered
            insuranceResult = nil
            insuranceMessage = ""
            // Delay checking for blackjacks to allow peek animation (for both dealer 10 and player blackjack)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.checkForBlackjacks()
            }
        } else {
            // Clear any previous insurance data since no insurance is offered
            insuranceResult = nil
            insuranceMessage = ""
            checkForBlackjacks()
        }
    }

    func playerRespondedToInsurance(insuranceTaken: Bool = false) {
        guard gameState == .offeringInsurance else { return }
        checkForBlackjacks(insuranceTaken: insuranceTaken)
    }
    
    func checkForBlackjackImmediately() {
        // Force check for blackjack immediately
        print("DEBUG: Checking for blackjack - playerHand.isBlackjack: \(playerHand.isBlackjack), gameState: \(gameState), currentBet: \(currentBet)")
        if playerHand.isBlackjack && gameState == .playerTurn {
            gameState = .gameOver
            payout = currentBet + (currentBet * 1.5)  // Return bet + 3:2 winnings for blackjack
            resultMessage = "Blackjack!"
            print("DEBUG: Blackjack detected! Payout set to: \(payout)")
        }
    }

    private func checkForBlackjacks(insuranceTaken: Bool = false) {
        // For insurance purposes, we need to check if dealer has blackjack with both cards
        // The dealer's hole card should be considered when calculating blackjack
        let dealerHasBJ = dealerHand.cards.count == 2 && dealerHand.value == 21
        let playerHasBJ = playerHand.isBlackjack
        
        // Only set insurance result and message if insurance was actually offered
        if gameState == .offeringInsurance {
            insuranceResult = dealerHasBJ
            
            // Only set insurance message if insurance was actually taken
            if insuranceTaken {
                if insuranceResult == true {
                    let insuranceBetAmount = currentBet / 2
                    let totalPayout = insuranceBetAmount * 3 // Original bet + 2:1 profit
                    insuranceMessage = "Insurance won! +$\(Int(totalPayout))" // 2:1 payout
                } else if insuranceResult == false {
                    insuranceMessage = ""
                } else {
                    insuranceMessage = ""
                }
            } else {
                // Insurance was declined, so no message
                insuranceMessage = ""
            }
        } else {
            // No insurance was offered, so clear any previous insurance data
            insuranceResult = nil
            insuranceMessage = ""
        }

        if dealerHasBJ {
            gameState = .gameOver
            if playerHasBJ {
                payout = currentBet  // Return the bet for push
                resultMessage = "Push!"
            } else {
                payout = -currentBet
                resultMessage = "You lose."
                // Play lose sound when dealer has blackjack and player doesn't
                SoundManager.shared.playLose()
            }
            return
        }

        if playerHasBJ {
            gameState = .gameOver
            payout = currentBet + (currentBet * 1.5)  // Return bet + 3:2 winnings for blackjack
            resultMessage = "Blackjack!"
            print("DEBUG: Blackjack detected in checkForBlackjacks! Payout set to: \(payout)")
            // Play blackjack sound
            SoundManager.shared.playBlackjack()
            return
        }
        gameState = .playerTurn
    }

    func hit() {
        guard gameState == .playerTurn else { return }
        
        // Play hit sound
        SoundManager.shared.playHit()
        
        if isUsingSplitManager() {
            hitCurrentSplitHand()
        } else {
            // Play card deal sound
            SoundManager.shared.playCardDeal()
            playerHand.addCard(deck.draw()!)
            if playerHand.isBust {
                resultMessage = "Bust! You lose!"
                payout = -currentBet
                gameState = .gameOver
                // Play bust sound
                SoundManager.shared.playBust()
                determineWinner()
            }
        }
    }

    func stand() {
        guard gameState == .playerTurn else { return }
        
        // Play stand sound
        SoundManager.shared.playStand()
        
        if isUsingSplitManager() {
            standCurrentSplitHand()
        } else {
            gameState = .dealerTurn
            // Note: UI will handle the animated dealer turn
        }
    }

    func canSplitHand(at index: Int) -> Bool {
        guard hands.count < maxHands else { return false }
        let hand = hands[index]
        return hand.canSplit
    }

    func splitHand(at index: Int, completion: @escaping () -> Void = {}) {
        guard canSplitHand(at: index) else { return }
        
        // Play split sound
        SoundManager.shared.playSplit()
        
        // Get the cards to be used for splitting with smart drawing
        guard let card1 = deck.draw() else { return }
        SoundManager.shared.playCardDeal() // First split card
        
        // Create a temporary hand with the first card to check for split opportunities
        let tempHand = SplitHand(initialCard: card1, bet: 0)
        guard let card2 = drawCardForSplitHand(for: tempHand) else { return }
        SoundManager.shared.playCardDeal() // Second split card
        
        // Use enhanced split manager
        let success = splitManager.splitHand(at: index, with: card1, newCard2: card2)
        guard success else { return }
        
        // Legacy compatibility
        let hand = hands[index]
        let newHand = Hand()
        
        // Move the second card to the new hand
        if let card = hand.removeLastCard() {
            newHand.addCard(card)
        }
        
        // Add new cards to each hand
        hand.addCard(card1)
        newHand.addCard(card2)
        
        // Insert the new hand and update tracking arrays
        hands.insert(newHand, at: index + 1)
        splitBets.insert(currentBet, at: index + 1)
        splitResults.insert("", at: index + 1)
        
        // Call completion after a short delay to allow for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion()
        }
    }
    
    // Enhanced split methods
    func canSplitCurrentHand() -> Bool {
        return splitManager.canSplitCurrentHand
    }
    
    func splitCurrentHand() -> Bool {
        let index = splitManager.activeHandIndex
        
        // Draw cards with smart drawing to avoid split opportunities
        guard let card1 = deck.draw() else { return false }
        
        // Create a temporary hand with the first card to check for split opportunities
        let tempHand = SplitHand(initialCard: card1, bet: 0)
        guard let card2 = drawCardForSplitHand(for: tempHand) else { return false }
        
        let success = splitManager.splitHand(at: index, with: card1, newCard2: card2)
        
        if success {
            // Update total bet tracking
            currentBet = splitManager.totalBet
            // Set the split phase to playing
            splitManager.splitPhase = .playing
        }
        
        return success
    }
    
    func hitCurrentSplitHand() {
        guard let card = deck.draw() else { return }
        // Play card deal sound
        SoundManager.shared.playCardDeal()
        let result = splitManager.processHandAction(SplitGameManager.HandAction.hit, for: splitManager.activeHandIndex, with: card)
        
        if result.shouldAdvanceHand {
            moveToNextSplitHand()
        }
    }
    
    func standCurrentSplitHand() {
        let result = splitManager.processHandAction(SplitGameManager.HandAction.stand, for: splitManager.activeHandIndex)
        
        if result.shouldAdvanceHand {
            moveToNextSplitHand()
        }
    }
    
    func doubleDownCurrentSplitHand() {
        // Play double down sound
        SoundManager.shared.playDoubleDown()
        
        guard let card = deck.draw() else { return }
        // Play card deal sound
        SoundManager.shared.playCardDeal()
        let result = splitManager.processHandAction(SplitGameManager.HandAction.doubleDown, for: splitManager.activeHandIndex, with: card)
        
        if result.success {
            currentBet = splitManager.totalBet
        }
        
        if result.shouldAdvanceHand {
            moveToNextSplitHand()
        }
    }
    
    private func moveToNextSplitHand() {
        let hasMoreHands = splitManager.moveToNextHand()
        
        if !hasMoreHands {
            // All hands complete, move to dealer turn
            gameState = .dealerTurn
            dealerPlayEnhanced()
        }
    }
    
    func dealerPlayEnhanced() {
        while dealerHand.value < 17 || (dealerHand.value == 17 && dealerHand.isSoft) {
            if let card = deck.draw() {
                dealerHand.addCard(card)
            }
        }
        
        // Start sequential resolution of split hands
        splitManager.activeHandIndex = 0
        determineWinnerEnhanced()
    }
    
    func determineWinnerEnhanced() {
        guard splitManager.activeHandIndex < splitManager.hands.count else {
            // All hands processed, complete the game
            splitManager.completeAllHands()
            gameState = .gameOver
            return
        }
        
        let currentHand = splitManager.hands[splitManager.activeHandIndex]
        let handResult = calculateHandResult(hand: currentHand, handIndex: splitManager.activeHandIndex)
        
        // Show result for current hand
        resultMessage = handResult.message
        payout += handResult.payout
        
        // Move to next hand after a delay to allow UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.splitManager.activeHandIndex += 1
            // Force UI refresh to show the new active hand
            DispatchQueue.main.async {
                // This will trigger UI refresh in the view
                NotificationCenter.default.post(name: NSNotification.Name("SplitHandIndexChanged"), object: nil)
            }
            self.determineWinnerEnhanced()
        }
    }
    
    private func calculateHandResult(hand: SplitHand, handIndex: Int) -> (message: String, payout: Double) {
        // Only show result message for the currently active hand
        let isActiveHand = handIndex == splitManager.activeHandIndex
        
        if hand.isBust {
            gameStats.recordPlayerBust()
            return (isActiveHand ? "Dealer Wins" : "", 0) // Loss: no payout, bet already deducted
        } else if dealerHand.isBust {
            gameStats.recordPlayerWin()
            return (isActiveHand ? "You Win" : "", hand.bet * 2) // Win: bet + winnings
        } else if dealerHand.value > hand.value {
            gameStats.recordPlayerLoss()
            return (isActiveHand ? "Dealer Wins" : "", 0) // Loss: no payout, bet already deducted
        } else if dealerHand.value < hand.value {
            gameStats.recordPlayerWin()
            return (isActiveHand ? "You Win" : "", hand.bet * 2) // Win: bet + winnings
        } else {
            gameStats.recordPush()
            return (isActiveHand ? "Push!" : "", hand.bet) // Push: return original bet
        }
    }

    func hitOnActiveHand() {
        guard gameState == .playerTurn else { return }
        let hand = splitManager.hands[splitManager.activeHandIndex]
        print("DEBUG: Hitting on active hand \(splitManager.activeHandIndex + 1), cards before: \(hand.cards.count)")
        
        // CASINO RULE: Check if this is a split ace hand that has already received its one additional card
        if hand.isSplitAceHand && hand.cards.count >= 3 {
            print("DEBUG: Cannot hit on split ace hand - already received one additional card")
            return
        }
        
        // Draw a card that won't create split opportunities during split hands
        if let card = drawCardAvoidingSplitOpportunities(for: hand) {
            print("DEBUG: Successfully drew card: \(card.display)")
            hand.addCard(card)
        } else {
            print("DEBUG: Failed to draw card for split hand")
        }
        print("DEBUG: Cards after hit: \(hand.cards.count)")
        
        // Auto-stand if busted or if split ace hand is now complete
        if hand.isBust || (hand.isSplitAceHand && hand.cards.count == 3) {
            print("DEBUG: Hand busted or split ace hand complete, auto-standing")
            standOnActiveHand()
        }
    }

    func standOnActiveHand() {
        guard gameState == .playerTurn else { return }
        
        // Mark current hand as complete
        let currentHand = splitManager.hands[splitManager.activeHandIndex]
        currentHand.stand() // Use the hand's stand method instead of directly setting isComplete
        
        print("DEBUG: Standing on hand \(splitManager.activeHandIndex + 1), total hands: \(splitManager.hands.count)")
        print("DEBUG: Current hand index: \(splitManager.activeHandIndex), hands count: \(splitManager.hands.count)")
        print("DEBUG: Current hand isComplete: \(currentHand.isComplete), status: \(currentHand.status)")
        
        // Check if there are more hands to play
        if splitManager.activeHandIndex < splitManager.hands.count - 1 {
            splitManager.activeHandIndex += 1
            let nextHand = splitManager.hands[splitManager.activeHandIndex]
            print("DEBUG: Advanced to hand \(splitManager.activeHandIndex + 1), total hands: \(splitManager.hands.count)")
            print("DEBUG: Next hand isComplete: \(nextHand.isComplete), status: \(nextHand.status)")
            
            // Check if the next hand is already complete (this shouldn't happen)
            if nextHand.isComplete {
                print("DEBUG: ERROR - Next hand is already complete! This shouldn't happen.")
                // Force it to be incomplete
                nextHand.isComplete = false
                nextHand.status = .playing
            }
        } else {
            // All hands are complete, move to dealer turn
            print("DEBUG: All hands complete, moving to dealer turn")
            gameState = .dealerTurn
            // Let the UI handle the animated dealer turn
        }
    }

    func canDoubleDownOnActiveHand(balance: Double) -> Bool {
        let hand = splitManager.hands[splitManager.activeHandIndex]
        
        print("🎯 canDoubleDownOnActiveHand check:")
        print("🎯 Hand cards count: \(hand.cards.count)")
        print("🎯 Hand value: \(hand.value)")
        print("🎯 Hand bet: \(hand.bet)")
        print("🎯 Balance: \(balance)")
        print("🎯 Is split ace hand: \(hand.isSplitAceHand)")
        
        // CASINO RULE: Cannot double down on split ace hands
        if hand.isSplitAceHand {
            print("🎯 Failed: Cannot double down on split ace hands")
            return false
        }
        
        // Must have exactly 2 cards
        guard hand.cards.count == 2 else { 
            print("🎯 Failed: Not exactly 2 cards")
            return false 
        }
        
        // Must have sufficient balance for additional bet
        guard balance >= hand.bet else { 
            print("🎯 Failed: Insufficient balance (\(balance) < \(hand.bet))")
            return false 
        }
        
        // Check if hand value allows doubling down
        let handValue = hand.value
        
        // Allow double down on any two-card hand that's not a natural blackjack
        // (Natural blackjack is Ace + 10-value card, but split hands can double on 21)
        let isNaturalBlackjack = handValue == 21 && hand.cards.count == 2 && 
                                (hand.cards[0].rank == .ace && hand.cards[1].rank.value == 10) ||
                                (hand.cards[1].rank == .ace && hand.cards[0].rank.value == 10)
        
        let canDouble = !isNaturalBlackjack && handValue <= 21
        print("🎯 Is natural blackjack: \(isNaturalBlackjack), Hand value: \(handValue), Can double: \(canDouble)")
        
        return canDouble
    }

    func doubleDownOnActiveHand(balance: Double) -> Double {
        print("🎯 doubleDownOnActiveHand called")
        print("🎯 canDoubleDownOnActiveHand: \(canDoubleDownOnActiveHand(balance: balance))")
        
        guard canDoubleDownOnActiveHand(balance: balance) else { 
            print("🎯 Double down guard failed")
            return 0 
        }
        
        // Get the current bet amount before doubling
        let currentBet = splitManager.hands[splitManager.activeHandIndex].bet
        let additionalBet = currentBet
        
        print("🎯 Current bet: \(currentBet), Additional bet: \(additionalBet)")
        
        // Double the bet in the split manager
        splitManager.hands[splitManager.activeHandIndex].bet *= 2
        splitBets[activeHandIndex] *= 2
        
        // Update total bet tracking
        self.currentBet = splitManager.totalBet
        
        // Use split manager for double down during split hands
        if isUsingSplitManager() {
            if let card = drawCardAvoidingSplitOpportunities(for: splitManager.hands[splitManager.activeHandIndex]) {
                splitManager.hands[splitManager.activeHandIndex].addCard(card)
            }
        } else {
            hands[activeHandIndex].addCard(deck.draw()!)
        }
        
        // Auto-stand after double down
        standOnActiveHand()
        
        // Return the additional bet amount for UI to deduct from balance
        return additionalBet
    }

    private func dealerPlay() {
        while dealerHand.value < 17 || (dealerHand.value == 17 && dealerHand.isSoft) {
            dealerHand.addCard(deck.draw()!)
        }
        determineWinner()
    }

    func determineWinner() {
        if playerHand.isBlackjack {
            resultMessage = "Blackjack!"
            payout = currentBet + (currentBet * 1.5)  // Return bet + 3:2 winnings
            // Play blackjack sound
            SoundManager.shared.playBlackjack()
            if dealerHand.isBlackjack {
                gameStats.recordPush()
            } else {
                gameStats.recordPlayerBlackjack()
            }
        } else if playerHand.isBust {
            resultMessage = "You lose."
            payout = -currentBet
            // Play lose sound
            SoundManager.shared.playLose()
            gameStats.recordPlayerBust()
        } else if dealerHand.isBust {
            resultMessage = "You win!"
            payout = currentBet * 2  // Return bet + equal winnings
            gameStats.recordPlayerWin()
        } else if dealerHand.value > playerHand.value {
            resultMessage = "You lose."
            payout = -currentBet
            gameStats.recordPlayerLoss()
        } else if dealerHand.value < playerHand.value {
            resultMessage = "You win!"
            payout = currentBet * 2  // Return bet + equal winnings
            gameStats.recordPlayerWin()
        } else {
            resultMessage = "Push!"
            payout = currentBet  // Return the bet for push
            gameStats.recordPush()
        }
        
        // Track dealer blackjack if player doesn't have blackjack
        if dealerHand.isBlackjack && !playerHand.isBlackjack {
            gameStats.recordDealerBlackjack()
        }
        
        // Play sound based on final result message
        if resultMessage == "You win!" {
            SoundManager.shared.playWin()
        } else if resultMessage == "You lose." {
            SoundManager.shared.playLose()
        } else if resultMessage == "Push!" {
            SoundManager.shared.playPush()
        }
        
        gameState = .gameOver
    }

    func doubleDownBet() {
        // Play double down sound
        SoundManager.shared.playDoubleDown()
        
        if isUsingSplitManager() {
            doubleDownCurrentSplitHand()
        } else {
            currentBet *= 2
        }
    }
    
    func canDoubleDown() -> Bool {
        if isUsingSplitManager() {
            return splitManager.canDoubleDownCurrentHand
        } else {
            return playerHand.cards.count == 2
        }
    }

    func reset() {
        gameState = .betting
        playerHand.clear()
        dealerHand.clear()
        resultMessage = ""
        currentBet = 0
        payout = 0
        insuranceResult = nil
        
        // Reset split manager
        splitManager.reset()
        
        // Reset legacy split data
        hands.removeAll()
        activeHandIndex = 0
        splitBets.removeAll()
        splitResults.removeAll()
    }
    
    // Enhanced game flow methods
    func isUsingSplitManager() -> Bool {
        return splitManager.hasSplit
    }
    
    func getCurrentActiveHand() -> SplitHand? {
        return splitManager.getActiveHand
    }
    
    func canPlayerAct() -> Bool {
        if isUsingSplitManager() {
            return splitManager.splitPhase == SplitGameManager.SplitPhase.playing && !splitManager.areAllHandsComplete
        } else {
            return gameState == .playerTurn
        }
    }
    
    func getHandsForDisplay() -> [SplitHand] {
        return splitManager.hands
    }
    
    func getTotalBetAmount() -> Double {
        return splitManager.totalBet
    }
    
    func getCurrentHandBet() -> Double {
        if let activeHand = splitManager.getActiveHand {
            return activeHand.bet
        }
        return currentBet
    }
    
    func getHandCount() -> Int {
        return splitManager.totalHandsCount
    }
    
    func getCurrentHandNumber() -> Int {
        return splitManager.currentHandNumber
    }
    
    func getRemainingPlayingHands() -> Int {
        return splitManager.playingHandsRemaining
    }
    
    // Re-splitting validation methods
    func canResplit() -> Bool {
        return splitManager.canSplitCurrentHand && splitManager.hands.count < splitManager.maxHands
    }
    
    func getRemainingResplits() -> Int {
        return max(0, splitManager.maxHands - splitManager.hands.count)
    }
    
    func validateSplitAction(balance: Double) -> (canSplit: Bool, reason: String?) {
        guard canResplit() else {
            if splitManager.hands.count >= splitManager.maxHands {
                return (false, "Maximum \(splitManager.maxHands) hands reached")
            } else {
                return (false, "Cannot split this hand")
            }
        }
        
        let requiredBet = getCurrentHandBet()
        guard balance >= requiredBet else {
            return (false, "Insufficient funds for split (need $\(Int(requiredBet)))")
        }
        
        return (true, nil)
    }
    
    func attemptSplit(balance: Double) -> (success: Bool, message: String?) {
        let validation = validateSplitAction(balance: balance)
        guard validation.canSplit else {
            return (false, validation.reason)
        }
        
        let success = splitCurrentHand()
        if success {
            return (true, "Hand split successfully!")
        } else {
            return (false, "Failed to split hand")
        }
    }

    func dealerPlaySplit() {
        // Don't deal cards here - let the UI handle the animated dealer turn
        // The UI will call dealerDrawOneCard() for each card with animation
        // Use enhanced resolution for individual hand processing
        splitManager.activeHandIndex = 0
        determineWinnerEnhanced()
    }

    private func determineWinnerSplit() {
        var totalPayout: Double = 0
        for i in 0..<hands.count {
            let hand = hands[i]
            if hand.isBust {
                splitResults[i] = "Hand \(i+1): Bust! You lose."
            } else if dealerHand.isBust {
                splitResults[i] = "Hand \(i+1): Dealer busts! You win!"
                totalPayout += splitBets[i]
            } else if dealerHand.value > hand.value {
                splitResults[i] = "Hand \(i+1): Dealer wins!"
            } else if dealerHand.value < hand.value {
                splitResults[i] = "Hand \(i+1): You win!"
                totalPayout += splitBets[i]
            } else {
                splitResults[i] = "Hand \(i+1): Push!"
                totalPayout += splitBets[i]  // Return the bet for push
            }
        }
        payout = totalPayout
        resultMessage = splitResults.joined(separator: "\n")
        gameState = .gameOver
    }

    // Add this function to support stepwise dealer play for animation
    /// Deals one card to the dealer. Returns true if the dealer is done (should stand or bust), false if more cards are needed.
    func dealerDrawOneCard() -> Bool {
        guard gameState == .dealerTurn else { return true }
        if dealerHand.value < 17 || (dealerHand.value == 17 && dealerHand.isSoft) {
            if let card = deck.draw() {
                // Play card deal sound
                SoundManager.shared.playCardDeal()
                dealerHand.addCard(card)
            }
        }
        // After drawing, check if dealer should continue
        let done = !(dealerHand.value < 17 || (dealerHand.value == 17 && dealerHand.isSoft))
        return done
    }
}

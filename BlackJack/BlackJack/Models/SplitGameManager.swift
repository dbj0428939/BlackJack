import Foundation
import Combine

// Import Card and Rank types from the same module
// These are needed for the split functionality

public class SplitHand: ObservableObject, Identifiable {
    public let id = UUID()
    @Published public var cards: [Card] = []
    @Published public var bet: Double
    @Published public var isComplete: Bool = false
    @Published public var isDoubledDown: Bool = false
    @Published public var isBusted: Bool = false
    @Published public var isBlackjack: Bool = false
    @Published public var isActive: Bool = false
    @Published public var canSplit: Bool = false
    @Published public var canDoubleDown: Bool = false
    @Published public var status: HandStatus = .playing
    
    public enum HandStatus {
        case playing
        case standing
        case stood
        case busted
        case bust
        case blackjack
        case complete
        case completed
    }
    
    public var isBust: Bool {
        return isBusted
    }
    
    public var value: Int {
        return calculateValue()
    }
    
    public var isSoft: Bool {
        var value = 0
        var aces = 0
        
        for card in cards {
            if card.rank == Rank.ace {
                aces += 1
            } else {
                value += card.value
            }
        }
        
        return aces > 0 && value + 11 + (aces - 1) <= 21
    }
    
    public init(initialCard: Card? = nil, bet: Double = 0) {
        self.bet = bet
        if let card = initialCard {
            self.cards.append(card)
        }
    }
    
    public func addCard(_ card: Card) {
        cards.append(card)
        print("DEBUG SPLIT HAND: Adding card \(card.display) to hand")
        print("DEBUG SPLIT HAND: Hand now has \(cards.count) cards, value: \(calculateValue())")
        updateHandStatus()
    }
    
    // Check if this is a split ace hand (starts with ace and has exactly 2 cards)
    public var isSplitAceHand: Bool {
        return cards.count == 2 && cards[0].rank == .ace && cards[1].rank == .ace
    }
    
    public func doubleDown(with card: Card) {
        bet *= 2
        addCard(card)
        isDoubledDown = true
        isComplete = true
    }
    
    private func updateHandStatus() {
        let handValue = calculateValue()
        isBusted = handValue > 21
        
        // For split hands, NEVER consider any 21 as a blackjack
        // Split hands should always allow hit/stand/double unless explicitly stood
        isBlackjack = false
        
        // CASINO RULE: Split aces get exactly one additional card and are then complete
        if isSplitAceHand && cards.count == 3 {
            // Split ace hand has received its one additional card, auto-complete
            isComplete = true
            status = .complete
            print("DEBUG SPLIT HAND: Split ace hand auto-completed after receiving one additional card")
        } else if isBusted {
            status = .busted
            isComplete = true
        } else if isComplete {
            // Only mark as complete if explicitly stood or doubled down
            status = .complete
        } else {
            status = .playing
            // CRITICAL FIX: Never auto-complete split hands (except split aces)
            // Only mark as complete if explicitly stood or doubled down
            isComplete = false
        }
        
        // Update canSplit and canDoubleDown
        if cards.count == 2 {
            let card1 = cards[0]
            let card2 = cards[1]
            // Allow splitting if same rank OR both cards have value 10 (J, Q, K, 10)
            canSplit = (card1.rank == card2.rank) || (card1.value == 10 && card2.value == 10)
        } else {
            canSplit = false
        }
        canDoubleDown = cards.count == 2 && !isComplete
    }
    
    public func calculateValue() -> Int {
        var total = 0
        var aces = 0
        for card in cards {
            if card.rank == .ace {
                aces += 1
                total += 11
            } else {
                total += card.value
            }
        }
        while total > 21 && aces > 0 {
            total -= 10
            aces -= 1
        }
        return total
    }
    
    public func stand() {
        isComplete = true
        status = .standing
    }
}

public class SplitGameManager: ObservableObject {
    @Published public var hands: [SplitHand] = []
    @Published public var activeHandIndex: Int = 0
    @Published public var splitPhase: SplitPhase = .none
    @Published public var totalBet: Double = 0
    public let maxHands: Int = 2
    
    public enum SplitPhase {
        case none
        case playing
        case dealerTurn
        case completed
    }
    
    public enum HandAction {
        case hit
        case stand
        case doubleDown
        case split
    }
    
    public struct ActionResult {
        public var success: Bool
        public var shouldAdvanceHand: Bool
        
        public init(success: Bool = true, shouldAdvanceHand: Bool = false) {
            self.success = success
            self.shouldAdvanceHand = shouldAdvanceHand
        }
    }
    
    public var activeHand: SplitHand? {
        guard activeHandIndex >= 0 && activeHandIndex < hands.count else { return nil }
        return hands[activeHandIndex]
    }
    
    public var hasSplit: Bool {
        return hands.count > 1
    }
    
    public var canSplitCurrentHand: Bool {
        return canSplitHand(at: activeHandIndex)
    }
    
    public var canDoubleDownCurrentHand: Bool {
        guard let hand = activeHand else { return false }
        // CASINO RULE: Cannot double down on split ace hands
        if hand.isSplitAceHand {
            return false
        }
        return hand.cards.count == 2 && hand.status == SplitHand.HandStatus.playing
    }
    
    public var getActiveHand: SplitHand? {
        return activeHand
    }
    
    public var areAllHandsComplete: Bool {
        return allHandsComplete()
    }
    
    public var totalHandsCount: Int {
        return hands.count
    }
    
    public var currentHandNumber: Int {
        return activeHandIndex + 1
    }
    
    public var playingHandsRemaining: Int {
        return hands.filter { !$0.isComplete }.count
    }
    
    public var currentHandIndex: Int {
        return activeHandIndex
    }
    
    public init() {
        // Initialize with an empty array of hands
    }
    
    public func reset() {
        hands.removeAll()
        activeHandIndex = 0
        splitPhase = .none
        totalBet = 0
    }
    
    public func initializeWithSingleHand(bet: Double) {
        createInitialHand(with: bet)
    }
    
    public func initializeWithSingleHand(with newCard2: Card) {
        // This method signature is called from BlackjackGame but seems incorrect
        // Adding it for compilation compatibility
    }
    
    public func createInitialHand(with bet: Double) {
        let hand = SplitHand(bet: bet)
        hand.isActive = true
        hands = [hand]
        totalBet = bet
        splitPhase = .playing
    }
    
    public func splitHand(at index: Int, with newCard1: Card, newCard2: Card) -> Bool {
        guard index >= 0 && index < hands.count else { return false }
        guard canSplitHand(at: index) else { return false }
        
        let originalHand = hands[index]
        guard originalHand.cards.count == 2 else { return false }
        
        // Create two new hands from the split
        let firstCard = originalHand.cards[0]
        let secondCard = originalHand.cards[1]
        
        let hand1 = SplitHand(initialCard: firstCard, bet: originalHand.bet)
        print("DEBUG SPLIT: Created hand1 with \(firstCard.display)")
        hand1.addCard(newCard1)
        print("DEBUG SPLIT: Hand1 after adding \(newCard1.display): value=\(hand1.value), isComplete=\(hand1.isComplete)")
        hand1.isActive = true
        
        let hand2 = SplitHand(initialCard: secondCard, bet: originalHand.bet)
        print("DEBUG SPLIT: Created hand2 with \(secondCard.display)")
        hand2.addCard(newCard2)
        print("DEBUG SPLIT: Hand2 after adding \(newCard2.display): value=\(hand2.value), isComplete=\(hand2.isComplete)")
        
        // Replace the original hand with the two new hands
        hands.remove(at: index)
        hands.insert(hand2, at: index)
        hands.insert(hand1, at: index)
        
        // Update active hand index and total bet
        activeHandIndex = index
        totalBet += originalHand.bet
        
        // Update hand states
        updateHandStates()
        
        return true
    }
    
    public func splitHand(at index: Int, newBet: Double) -> Bool {
        guard index >= 0 && index < hands.count else { return false }
        guard canSplitHand(at: index) else { return false }
        
        let originalHand = hands[index]
        guard originalHand.cards.count == 2 else { return false }
        
        // Create two new hands from the split
        let firstCard = originalHand.cards[0]
        let secondCard = originalHand.cards[1]
        
        let hand1 = SplitHand(initialCard: firstCard, bet: originalHand.bet)
        hand1.isActive = true
        
        let hand2 = SplitHand(initialCard: secondCard, bet: originalHand.bet)
        
        // Replace the original hand with the two new hands
        hands.remove(at: index)
        hands.insert(hand2, at: index)
        hands.insert(hand1, at: index)
        
        // Update active hand index and total bet
        activeHandIndex = index
        totalBet += originalHand.bet
        
        // Update hand states
        updateHandStates()
        
        return true
    }
    
    @discardableResult
    public func moveToNextHand() -> Bool {
        if activeHandIndex < hands.count - 1 {
            hands[activeHandIndex].isActive = false
            activeHandIndex += 1
            hands[activeHandIndex].isActive = true
            return true
        } else {
            // All hands have been played
            hands[activeHandIndex].isActive = false
            splitPhase = .dealerTurn
            return false
        }
    }
    
    public func shouldAdvanceHand() -> Bool {
        guard let hand = activeHand else { return false }
        return hand.isComplete
    }
    
    public func canSplitHand(at index: Int) -> Bool {
        guard index >= 0 && index < hands.count else { return false }
        let hand = hands[index]
        
        // Can only split the original hand (index 0) and only if we haven't already split
        guard index == 0 && hands.count == 1 else { return false }
        
        // Can only split if there are exactly 2 cards of the same rank
        if hand.cards.count == 2 {
            let card1 = hand.cards[0]
            let card2 = hand.cards[1]
            
            // Allow splitting if same rank OR both cards have value 10 (J, Q, K, 10)
            let canSplitCards = (card1.rank == card2.rank) || (card1.value == 10 && card2.value == 10)
            
            return canSplitCards && hand.status == SplitHand.HandStatus.playing
        }
        
        return false
    }
    
    public func processHandAction(_ action: HandAction, for handIndex: Int) -> ActionResult {
        guard handIndex >= 0 && handIndex < hands.count else { return ActionResult(success: false, shouldAdvanceHand: false) }
        let hand = hands[handIndex]
        
        switch action {
        case .stand:
            hand.stand()
            return ActionResult(success: true, shouldAdvanceHand: true)
        case .hit, .doubleDown, .split:
            // These actions are handled by the BlackjackGame class
            return ActionResult(success: false, shouldAdvanceHand: false)
        }
    }
    
    public func processHandAction(_ action: HandAction, for handIndex: Int, with card: Card) -> ActionResult {
        guard handIndex >= 0 && handIndex < hands.count else { return ActionResult(success: false, shouldAdvanceHand: false) }
        let hand = hands[handIndex]
        
        switch action {
        case .hit:
            // CASINO RULE: Cannot hit on split ace hands that have already received their one additional card
            if hand.isSplitAceHand && hand.cards.count >= 3 {
                print("DEBUG SPLIT HAND: Cannot hit on split ace hand - already received one additional card")
                return ActionResult(success: false, shouldAdvanceHand: false)
            }
            
            hand.addCard(card)
            // Only advance if busted or if split ace hand is now complete
            if hand.isBust || (hand.isSplitAceHand && hand.cards.count == 3) {
                return ActionResult(success: true, shouldAdvanceHand: true)
            }
            return ActionResult(success: true, shouldAdvanceHand: false)
            
        case .doubleDown:
            // CASINO RULE: Cannot double down on split ace hands
            if hand.isSplitAceHand {
                print("DEBUG SPLIT HAND: Cannot double down on split ace hand")
                return ActionResult(success: false, shouldAdvanceHand: false)
            }
            
            if hand.cards.count != 2 || hand.status != SplitHand.HandStatus.playing {
                return ActionResult(success: false, shouldAdvanceHand: false)
            }
            
            hand.bet *= 2
            totalBet += hand.bet / 2
            hand.addCard(card)
            hand.stand()
            return ActionResult(success: true, shouldAdvanceHand: true)
            
        case .stand, .split:
            return ActionResult(success: false, shouldAdvanceHand: false)
        }
    }
    
    public func updateHandStates() {
        for (index, hand) in hands.enumerated() {
            // Update canSplit and canDoubleDown properties
            hand.canSplit = canSplitHand(at: index)
            // CASINO RULE: Cannot double down on split ace hands
            hand.canDoubleDown = hand.cards.count == 2 && hand.status == SplitHand.HandStatus.playing && !hand.isSplitAceHand
            
            // Check if hand is active
            hand.isActive = index == activeHandIndex && splitPhase == .playing
        }
    }
    
    public func allHandsComplete() -> Bool {
        return hands.allSatisfy { $0.isComplete }
    }
    
    public func completeAllHands() {
        for hand in hands {
            if hand.status == SplitHand.HandStatus.playing {
                hand.status = SplitHand.HandStatus.completed
            }
        }
    }
}
import Foundation
import SwiftUI

// Ensure Card and Rank types are available
// These should be automatically available within the same module

public class Hand: ObservableObject {
    @Published var cards: [Card] = []
    
    public init() {
        cards = []
    }
    
    public func addCard(_ card: Card) {
        cards.append(card)
    }
    
    public func clear() {
        cards.removeAll()
    }

    public func removeLastCard() -> Card? {
        return cards.popLast()
    }
    
    public var value: Int {
        var value = 0
        var aces = 0
        
        for card in cards {
            if card.rank == Rank.ace {
                aces += 1
            } else {
                value += card.value
            }
        }
        
        // Add aces
        for _ in 0..<aces {
            if value + 11 <= 21 {
                value += 11
            } else {
                value += 1
            }
        }
        
        return value
    }
    
    public func dealerValue(isDealerTurn: Bool) -> Int {
        if !isDealerTurn {
            guard let firstCard = cards.first else { return 0 }
            return firstCard.rank == Rank.ace ? 11 : firstCard.value
        }
        return value
    }
    
    public var isBlackjack: Bool {
        cards.count == 2 && value == 21
    }
    
    public var isBust: Bool {
        value > 21
    }
    
    public var canSplit: Bool {
        if cards.count == 2 {
            let card1 = cards[0]
            let card2 = cards[1]
            // Allow splitting if same rank OR both cards have value 10 (J, Q, K, 10)
            return (card1.rank == card2.rank) || (card1.value == 10 && card2.value == 10)
        }
        return false
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
}

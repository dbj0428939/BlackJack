import Foundation

public class Deck {
    public private(set) var cards: [Card] = []

    public init() {
        reset()
    }

    public func reset() {
        cards = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(suit: suit, rank: rank))
            }
        }
        shuffle()
    }

    public func shuffle() {
        cards.shuffle()
        // Play shuffle sound
        SoundManager.shared.playShuffle()
    }

    public func draw() -> Card? {
        return cards.popLast()
    }
}

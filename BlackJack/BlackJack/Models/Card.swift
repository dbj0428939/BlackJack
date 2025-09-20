import Foundation

public enum Suit: String, CaseIterable {
    case hearts = "♥️", diamonds = "♦️", clubs = "♣️", spades = "♠️"
}

public enum Rank: Int, CaseIterable {
    case ace = 1, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king
    
    var stringValue: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return "\(rawValue)"
        }
    }
    
    var value: Int {
        switch self {
        case .ace: return 11
        case .jack, .queen, .king: return 10
        default: return rawValue
        }
    }
    
    var display: String {
        return stringValue
    }
}

public struct Card: Hashable, Identifiable {
    public let id = UUID()
    public let suit: Suit
    public let rank: Rank
    
    public init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
    }
    
    public var value: Int {
        switch rank {
        case .ace: return 11
        case .jack, .queen, .king: return 10
        default: return rank.rawValue
        }
    }
    
    public var display: String {
        return "\(rank.stringValue)\(suit.rawValue)"
    }
}
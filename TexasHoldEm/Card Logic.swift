//
//  Card Logic.swift
//  TexasHoldEm
//
//  Created by David Granger on 8/3/23.
//

import Foundation
import UIKit

enum Suit: String, Codable {
    case spades = "SPADES"
    case diamonds = "DIAMONDS"
    case hearts = "HEARTS"
    case clubs = "CLUBS"
}

enum PlayingCardValue: Int {
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13
    case ace = 14
}

enum HandType: Int, Comparable, CustomStringConvertible {
    static func < (lhs: HandType, rhs: HandType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    //ranked using int
    //in order of worst to best, commented out bc im unfamiliar with the rules
    case highCard = 1
    case pair = 2
    case twoPair = 3
    case threeOfAKind = 4
    case straight = 5 //different suits, cards in numeric order
    case flush = 6//same suit
    case fullHouse = 7 //three cards of one rank, two of another rank, comparing the three determines winner, if the three are the same, then the two determines the winner
    case fourOfAKind = 8
    case straightFlush  = 9 //same suits, cards in numeric order
    case royalFlush = 10 //best possible hand, 10-A same suit
    
    var description: String {
        switch self {
        case .highCard: return "High Card"
        case .pair: return "Pair"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        case .royalFlush: return "Royal Flush"
        }
    }
}

struct Hand: Hashable {
    static func == (lhs: Hand, rhs: Hand) -> Bool {
        return lhs.cards == rhs.cards
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(cards)
    }
    
    let cards: [Card]
    var handType: HandType?
    
    init?(cards: [Card]) {
        guard cards.count == 5 else { return nil }
        self.cards = cards
    }
}

struct Card: Codable, Equatable, Hashable {
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.value == rhs.value &&
        lhs.suit == rhs.suit
    }
    
    let value: String
    let suit: Suit
}

func integerValue(of cardValue: String) -> Int {
    switch cardValue {
    case "1": return 10 //10's first number is 1
    case "2": return 2
    case "3": return 3
    case "4": return 4
    case "5": return 5
    case "6": return 6
    case "7": return 7
    case "8": return 8
    case "9": return 9
    case "J": return 11
    case "Q": return 12
    case "K": return 13
    case "A": return 14
    default: return 0
    }
}

func determineHandType(hand: Hand) -> HandType {
    var values: [Int] = []
    var suits: [Suit: Int] = [:]
    var valueCounts: [Int: Int] = [:]
    
    for card in hand.cards {
        guard let firstLetter = card.value.first else {return .highCard}
        let intValue = integerValue(of: String(describing: firstLetter))
        values.append(intValue)
        suits[card.suit, default: 0] += 1
        valueCounts[intValue, default: 0] += 1
    }
    
    values.sort()
    
    let isFlush = suits.values.contains { $0 == 5 }
    let isStraight = values.enumerated().allSatisfy { index, value in
        index == 0 || values[index - 1] + 1 == value
    }
    
    if isFlush {
        if isStraight {
            if values == [10, 11, 12, 13, 14] {
                return .royalFlush
            } else {
                return .straightFlush
            }
        }
        return .flush
    }
    
    if isStraight {
        return .straight
    }
    
    let counts = valueCounts.values.sorted(by: >)
    
    if counts[0] == 4 {
        return .fourOfAKind
    }
    
    if counts[0] == 3 && counts[1] == 2 {
        return .fullHouse
    }
    
    if counts[0] == 3 {
        return .threeOfAKind
    }
    
    if counts[0] == 2 && counts[1] == 2 {
        return .twoPair
    }
    
    if counts[0] == 2 {
        return .pair
    }
    
    return .highCard
}

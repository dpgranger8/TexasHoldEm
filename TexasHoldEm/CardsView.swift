//
//  ContentView.swift
//  TexasHoldEm
//
//  Created by David Granger on 8/3/23.
//

import SwiftUI

struct ContentView: View {
    @State var hands: [Hand] = [
        Hand(cards: [
            Card(value: "3", suit: .hearts),
            Card(value: "3", suit: .clubs),
            Card(value: "6", suit: .hearts),
            Card(value: "5", suit: .hearts),
            Card(value: "6", suit: .hearts)
        ])!,
        Hand(cards: [
            Card(value: "4", suit: .diamonds),
            Card(value: "7", suit: .diamonds),
            Card(value: "4", suit: .clubs),
            Card(value: "7", suit: .hearts),
            Card(value: "6", suit: .diamonds)
        ])!,
    ]
    @State var determineDisabled: Bool = false
    @State var counter: Int = 0
    @State var numberOfHands: Int = 0
    let handOptions = [1, 2, 3, 4, 5, 6]
    @State private var winnerIndex: Int? = nil
    @State private var winnerHandType: HandType? = nil
    static var tempHand: Hand = Hand(cards: [Card(value: "2", suit: .diamonds)])!
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                hands.removeAll()
            } label: {
                Text("Delete all hands")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding()
            
            Picker("Number of Hands", selection: $numberOfHands) {
                ForEach(handOptions, id: \.self) { hand in
                    Text("\(hand)").tag(hand)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            
            
            Button {
                if hands.count > 0 {
                    hands.removeAll()
                }
                Task {
                    determineDisabled = true
                    do {
                        for _ in 0..<numberOfHands {
                            var hand: Hand?
                            try await hand = CardsController.shared.getHand()
                            if var hand = hand {
                                hand.handType = determineHandType(hand: hand)
                                hands.append(hand)
                            }
                        }
                    } catch {
                        print("An error occurred: \(error)")
                    }
                    determineDisabled = false
                }
            } label: {
                HStack {
                    Text("Generate hands")
                        .frame(maxWidth: .infinity)
                    if determineDisabled {
                        DotLoadingView()
                            .frame(height: 15)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            VStack {
                Button {
                    let winningHand = determineWinner(hands: hands)
                    winnerIndex = hands.firstIndex(where: { $0 == winningHand })
                    winnerHandType = determineHandType(hand: winningHand)
                } label: {
                    Text("Check for the winner")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding()
                .disabled(determineDisabled)
                if let winnerIndex = winnerIndex, let winnerHandType = winnerHandType {
                    Text("Winner: Hand #\(winnerIndex + 1), with a \(winnerHandType.description)")
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        
        List {
            ForEach(Array(hands.enumerated()), id: \.element) { index, hand in
                Section {
                    ForEach(hand.cards, id: \.self) { card in
                        HStack {
                            Text("\(card.value.lowercased().capitalized) of \(card.suit.rawValue.lowercased())")
                        }
                    }
                } header: {
                    Text("Hand #\(index + 1)")
                }
            }
        }
        .listStyle(.sidebar)
    }
}

/// determineWinner will take in an array of "Poker" hands and determine which hand is better (according to texas holdem rules).
/// Traditionally in Texas Holdem you are only given 2 cards and then 5 other cards are placed flipped up in front of everyone.
/// In our version each player is given 5 cards with no cards placed on the table.
/// Based on just the 5 cards given in a hand. You are to determine what type of winning hands a player has and which is best.
/// For example a player may have a 2 of a kind and a 3 of a kind in a single hand. 3 of a kind is better than 2 of a kind and should be used to determine if their hand is better than any of the other players hands.
///
/// - Returns: Hand - Which is the hand that won. It is expected that the handType property("2 of a kind", "3 of a kind", "4 of a kind", etc) will have a value when returning the winning hand.
///

func determineWinner(hands: [Hand]) -> Hand {
    var bestHand: Hand? = nil
    var bestHandType: HandType = .highCard
    var bestHandRank: Int = 0
    
    for hand in hands {
        let handType = determineHandType(hand: hand)
        print(handType)
        
        if handType > bestHandType {
            bestHandType = handType
            bestHand = hand
        } else if handType == bestHandType {
            let handRank = handRank(hand: hand, type: handType)
            if handRank > bestHandRank {
                bestHandRank = handRank
                bestHand = hand
            }
        }
    }
    
    return bestHand!
}

func handRank(hand: Hand, type: HandType) -> Int {
    let valueCounts = hand.cards.reduce(into: [:]) { counts, card in
        counts[integerValue(of: card.value), default: 0] += 1
    }
    
    switch type {
    case .fourOfAKind, .threeOfAKind, .pair:
        // Return the value of the matching cards
        return valueCounts.filter { $0.value == type.rawValue }.keys.max() ?? 0
    case .fullHouse:
        // Return the value of the three matching cards, then the two matching cards
        let three = valueCounts.filter { $0.value == 3 }.keys.max() ?? 0
        let two = valueCounts.filter { $0.value == 2 }.keys.max() ?? 0
        return three * 100 + two // Weights the three matching cards more heavily
    case .flush, .highCard:
        // Return the value of the highest card
        return integerValue(of: hand.cards.max(by: { integerValue(of: $0.value) < integerValue(of: $1.value) })?.value ?? "")
    case .straight, .straightFlush, .royalFlush:
        // Return the value of the highest card in the straight
        return integerValue(of: hand.cards.max(by: { integerValue(of: $0.value) < integerValue(of: $1.value) })?.value ?? "")
    case .twoPair:
        // Return the value of the highest pair, then the value of the lower pair
        let pairs = valueCounts.filter { $0.value == 2 }.keys.sorted(by: >)
        return pairs[0] * 100 + pairs[1]
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

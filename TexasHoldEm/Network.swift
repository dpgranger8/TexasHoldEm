//
//  Network.swift
//  TexasHoldEm
//
//  Created by David Granger on 8/3/23.
//

import Foundation

class CardsController {
    //Initialize reusable decoder and session
    let decoder = JSONDecoder()
    let session = URLSession.shared
    static let shared = CardsController()
    let newDeckUrl = "https://www.deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1"
    let cardsUrl = "https://www.deckofcardsapi.com/api/deck/"

    enum APIError: Error, LocalizedError {
        case invalidResponse
        case wasNot200
    }

    func getDeck() async throws -> DeckCreationResponse {
        //Initialize our request
        var request = URLRequest(url: URL(string: newDeckUrl)!)
        
        //Set request items
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //Make the request
        let (data, response) = try await session.data(for: request)
        
        //Ensure a good response from the API
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print(httpResponse) //prints the response for debugging purposes if the request fails for any reason
            throw APIError.wasNot200
        }
        
        let deck = try decoder.decode(DeckCreationResponse.self, from: data)
        
        return deck
    }
    
    func getHand() async throws -> Hand? {
        //Initialize our request
        let deckID = try await getDeck().deck_id //get deck ID
        var request = URLRequest(url: URL(string: cardsUrl + deckID + "/draw/?count=5")!)
        
        //Set the request items
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //Make the request
        let (data, response) = try await session.data(for: request)
        
        //Ensure a good response from the API
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print(httpResponse) //prints the response for debugging purposes if the request fails for any reason
            throw APIError.wasNot200
        }
        
        let cardResponse = try decoder.decode(CardResponse.self, from: data)
        
        return Hand(cards: cardResponse.cards)
    }
}

struct DeckCreationResponse: Codable {
    let success: Bool
    let deck_id: String
    let shuffled: Bool
    let remaining: Int
}

struct CardResponse: Codable {
    let success: Bool
    let deck_id: String
    let cards: [Card]
    let remaining: Int
}

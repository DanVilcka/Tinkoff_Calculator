//
//  Storage.swift
//  TinkoffCalculator
//
//  Created by Daniil Vilchinskiy on 22.07.2024.
//

import Foundation

struct Calculation {
    let expression: [CalculationHistoryItem]
    let result: Double
}

extension Calculation: Codable {
    
}

extension CalculationHistoryItem: Codable {
    
    enum CodingKeys: String, CodingKey {
        case number
        case operation
    }
    
    enum CalculationHistoryItemError: Error {
        case ItemNotFound
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        
        switch self {
        case .number(let value):
            try container.encode(value, forKey: CodingKeys.number)
        case .operation(let value):
            try container.encode(value.rawValue, forKey: CodingKeys.operation)
        }
    }
    
    init(from decoder: any Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let number = try container.decodeIfPresent(Double.self, forKey: .number) {
            self = .number(number)
            return
        }
        
        if let rawOperation = try container.decodeIfPresent(String.self, forKey: .operation), let operation = Operation(rawValue: rawOperation) {
            self = .operation(operation)
            return
        }
        
        throw CalculationHistoryItemError.ItemNotFound
    }
}


class CalculationHistoryStorage {
    
    static let calculatioistoryKey = "calculatioistoryKey"
    
    func setHistory(calculation: [Calculation]) {
        if let encoded = try? JSONEncoder().encode(calculation) {
            UserDefaults.standard.set(encoded, forKey: CalculationHistoryStorage.calculatioistoryKey)
        }
    }
    
    func loadHistory() -> [Calculation] {
        if let data = UserDefaults.standard.data(forKey: CalculationHistoryStorage.calculatioistoryKey) {
            return (try? JSONDecoder().decode([Calculation].self, from: data)) ?? []
        }
        
        return []
    }
}

//
//  HealthDataValue.swift
//  MyHealth
//
//  Created by Bao Bui on 9/25/23.
//

import Foundation

class quantityDataValue: HealthDataValue, Codable {
    var value: Double
    var secondaryValue: Double?
    
    var displayString: String {
            var result = String(format: "%.0f", value)
            if let secondaryValue = secondaryValue {
                result += "/\(String(format: "%.0f", secondaryValue))"
            }
            
            return result
    }
    
    init(identifier: String, startDate: Date, endDate: Date, value: Double, seconddaryValue: Double? = nil) {
        self.value = value
        super.init(identifier: identifier, startDate: startDate, endDate: endDate)
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier = "identifier"
        case value = "value"
        case startDate = "start"
        case endDate = "end"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(String.self, forKey: .identifier)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy hh:mm:ss"
        
        let startStr = try container.decode(String.self, forKey: .startDate)
        let endStr = try container.decode(String.self, forKey: .endDate)
        
        let startDate = formatter.date(from: startStr)!
        let endDate = formatter.date(from: endStr)!
        
        self.value = try container.decode(Double.self, forKey: .value)
        super.init(identifier: identifier, startDate: startDate, endDate: endDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.value, forKey: .value)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy hh:mm:ss"
        
        let startStr = formatter.string(from: self.startDate)
        let endStr = formatter.string(from: self.endDate)
        
        try container.encode(startStr, forKey: .startDate)
        try container.encode(endStr, forKey: .endDate)
    }
}

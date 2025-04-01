//
//  categoryDataValue.swift
//  MyHealth
//
//  Created by Bao Bui on 12/1/23.
//

import Foundation
import HealthKit

class categoryDataValue: HealthDataValue, Codable {
    var value: Int
    
    init(identifier: String, startDate: Date, endDate: Date, value: Int) {
        self.value = value
        super.init(identifier: identifier, startDate: startDate, endDate: endDate)
    }
    
    init(identifier: String, from value: HKCategorySample) {
        self.value = value.value
        super.init(identifier: identifier, startDate: value.startDate, endDate: value.endDate)
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier = "identifier"
        case value = "value"
        case startDate = "start"
        case endDate = "end"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(Double(self.value), forKey: .value)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        
        let startStr = formatter.string(from: self.startDate)
        let endStr = formatter.string(from: self.endDate)
        
        try container.encode(startStr, forKey: .startDate)
        try container.encode(endStr, forKey: .endDate)
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
        
        self.value = Int(try container.decode(Double.self, forKey: .value))
        super.init(identifier: identifier, startDate: startDate, endDate: endDate)
    }
}

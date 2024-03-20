//
//  HealthDataValue.swift
//  MyHealth
//
//  Created by Bao Bui on 9/25/23.
//

import Foundation

class quantityDataValue: HealthDataValue {
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
    
}

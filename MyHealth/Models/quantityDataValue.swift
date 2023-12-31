//
//  HealthDataValue.swift
//  MyHealth
//
//  Created by Bao Bui on 9/25/23.
//

import Foundation

struct quantityDataValue: Identifiable {
    var id = UUID().uuidString
    
    var identifier: String
    let startDate: Date
    let endDate: Date
    var value: Double
    var secondaryValue: Double? = nil
    
    var displayString: String {
            var result = String(format: "%.0f", value)
            if let secondaryValue = secondaryValue {
                result += "/\(String(format: "%.0f", secondaryValue))"
            }
            
            return result
    }
}

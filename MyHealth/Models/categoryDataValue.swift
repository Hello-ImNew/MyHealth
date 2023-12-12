//
//  categoryDataValue.swift
//  MyHealth
//
//  Created by Bao Bui on 12/1/23.
//

import Foundation

class categoryDataValue: HealthDataValue {
    var value: Int
    
    init(identifier: String, startDate: Date, endDate: Date, value: Int) {
        self.value = value
        super.init(identifier: identifier, startDate: startDate, endDate: endDate)
    }
}

//
//  HealthDataValue.swift
//  MyHealth
//
//  Created by Bao Bui on 12/6/23.
//

import Foundation

class HealthDataValue : Identifiable {
    var id = UUID().uuidString
    
    var identifier: String
    let startDate: Date
    let endDate: Date
    
    init(identifier: String, startDate: Date, endDate: Date) {
        self.identifier = identifier
        self.startDate = startDate
        self.endDate = endDate
    }
}

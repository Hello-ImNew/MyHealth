//
//  HealthDataValue.swift
//  MyHealth
//
//  Created by Bao Bui on 9/25/23.
//

import Foundation

struct HealthDataValue: Identifiable {
    var id = UUID().uuidString
    
    let startDate: Date
    let endDate: Date
    var value: Double
}

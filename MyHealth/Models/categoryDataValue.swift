//
//  categoryDataValue.swift
//  MyHealth
//
//  Created by Bao Bui on 12/1/23.
//

import Foundation

struct categoryDataValue: Identifiable {
    let id: String = UUID().uuidString
    let identifier: String
    let startDate: Date
    let endDate: Date
    var value: Int
}

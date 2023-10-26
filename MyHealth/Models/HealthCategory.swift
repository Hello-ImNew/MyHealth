//
//  HealthCategory.swift
//  MyHealth
//
//  Created by Bao Bui on 10/18/23.
//

import Foundation
import HealthKit
import UIKit

class HealthCategory {
    let categoryName: String
    let dataTypes: [HKSampleType]
    let icon: String
    let color: UIColor
    
    init(categoryName: String, dataTypes: [HKSampleType], icon: String, color: UIColor) {
        self.categoryName = categoryName
        self.dataTypes = dataTypes
        self.icon = icon
        self.color = color
    }
}

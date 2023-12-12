//
//  DateSupport.swift
//  MyHealth
//
//  Created by Bao Bui on 10/6/23.
//

import Foundation
import UIKit

extension Date {
    var isWithinLast7Days: Bool? {
        // Create a Calendar instance
        let calendar = Calendar.current
        
        // Calculate the date 7 days ago from the current date
        if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date())) {
            // Compare the date with sevenDaysAgo
            if calendar.compare(self, to: sevenDaysAgo, toGranularity: .day) == .orderedDescending {
                return true
            } else {
                return false
            }
        } else {
            return nil
        }
    }
    
    var isWithinLast30Days: Bool? {
        // Create a Calendar instance
        let calendar = Calendar.current
        
        // Calculate the date 7 days ago from the current date
        if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: Date())) {
            // Compare the date with sevenDaysAgo
            if calendar.compare(self, to: thirtyDaysAgo, toGranularity: .day) == .orderedDescending {
                return true
            } else {
                return false
            }
        } else {
            return nil
        }
    }
    
    var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self)
    }
    
    var toString: String {
        let dateFormatter = DateFormatter()
        
        let current = Calendar.current
        let currentYear = current.component(.year, from: Date())
        let targetYear = current.component(.year, from: self)
        
        if currentYear != targetYear {
            dateFormatter.dateFormat = "MMM d, yyyy"
        } else {
            if current.isDate(self, inSameDayAs: Date()) {
                dateFormatter.dateFormat = "hh:mm"
            } else {
                dateFormatter.dateFormat = "MMM d"
            }
        }
        
        return dateFormatter.string(from: self)
    }
    
    var standardString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        return dateFormatter.string(from: self)
    }
    
    var age: Int {
        let ageComponent = Calendar.current.dateComponents([.year], from: self, to: Date())
        return ageComponent.year!
    }
}

func showAlert(title: String, message: String) -> UIAlertController {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "OK", style: .cancel)
    alertController.addAction(cancelAction)
    return alertController
}

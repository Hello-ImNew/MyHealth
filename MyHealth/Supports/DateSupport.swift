//
//  DateSupport.swift
//  MyHealth
//
//  Created by Bao Bui on 10/6/23.
//

import Foundation

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
}

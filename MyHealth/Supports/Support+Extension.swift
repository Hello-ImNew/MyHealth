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

extension UIImage {
    func resizeImage(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension UIViewController : settingViewDelegate {
    func addProfilePicture() {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.imageView?.contentMode = .scaleAspectFit
        let image = ViewModels.profileImage?.resizeImage(to: button.frame.size)
        button.setBackgroundImage(image, for: .normal)
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        button.addTarget(self, action: #selector(toSettingPage), for: .touchUpInside)
    }
    
    @objc private func toSettingPage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "SettingController") as? SettingViewController
        let navVC = UINavigationController(rootViewController: controller!)
        controller?.isDetailedView = true
        controller?.delegate = self
        self.showDetailViewController(navVC, sender: self)
    }
}

func showAlert(title: String, message: String) -> UIAlertController {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "OK", style: .cancel)
    alertController.addAction(cancelAction)
    return alertController
}

func dateIntervalToString(from start: Date?, to end: Date?) -> String {
    let dateIntervalFormatter = DateIntervalFormatter()
    dateIntervalFormatter.dateStyle = .medium
    dateIntervalFormatter.timeStyle = .none
    
    return dateIntervalFormatter.string(from: start!, to: end!)
}

func mergeTimeIntervals(data : [categoryDataValue]) -> [(start: Date, end: Date)] {
    var timeIntervals: [(start: Date, end: Date)] = []
    var index = 0
    for d in data {
        if timeIntervals.isEmpty {
            timeIntervals.append((d.startDate, d.endDate))
            continue
        }
        if d.startDate > timeIntervals[index].end {
            timeIntervals.append((d.startDate, d.endDate))
            index += 1
            continue
        }
        
        if d.startDate < timeIntervals[index].end {
            timeIntervals[index].end = max(d.endDate, timeIntervals[index].end)
            continue
        }
    }
    
    return timeIntervals
}

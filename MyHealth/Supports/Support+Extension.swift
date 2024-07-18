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
    
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        return formatter.string(from: self)
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
        ViewModels.getImageFromPath(path: ViewModels.userData.imgPath, completion: { image in
            DispatchQueue.main.async {
                button.setBackgroundImage(image, for: .normal)
            }
            
        })
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
    
    func showAlert(title: String, message: String) {
        let alert = createAlert(title: title, message: message)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}

func createAlert(title: String, message: String) -> UIAlertController {
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

func mergeTimeIntervals(data: [categoryDataValue]) -> [(start: Date, end: Date)] {
    var timeIntervals: [(start: Date, end: Date)] = []
    var index = 0
    var filteredData: [categoryDataValue] = []
    data.filter({$0.value != 0}).forEach({d in
        let current = Calendar.current
        let t1 = current.date(byAdding: .hour, value: 6, to: d.startDate)!
        let t2 = current.date(byAdding: .hour, value: 6, to: d.endDate)!
        
        if current.isDate(t1, inSameDayAs: t2) {
            filteredData.append(d)
        } else {
            filteredData.append(
                categoryDataValue(identifier: d.identifier,
                                  startDate: d.startDate,
                                  endDate: current.date(bySettingHour: 18, minute: 00, second: 00, of: d.startDate)!,
                                  value: d.value))
            filteredData.append(
                categoryDataValue(identifier: d.identifier,
                                  startDate: current.date(bySettingHour: 18, minute: 00, second: 00, of: d.startDate)!,
                                  endDate: d.endDate,
                                  value: d.value))
        }
            
    })
    
    for d in filteredData {
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

func beginningOfNextDay(_ date: Date) -> Date {
    let current = Calendar.current
    let result = current.startOfDay(for: current.date(byAdding: .day, value: 1, to: date)!)
    return result
}

func isValidUUID(for str: String) -> Bool {
    if let _ = UUID(uuidString: str) {
        return true
    }
    else {
        return false
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let shape = CAShapeLayer()
        shape.path = maskPath.cgPath
        layer.mask = shape
    }
}

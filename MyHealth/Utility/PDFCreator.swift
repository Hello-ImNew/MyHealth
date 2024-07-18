//
//  PDFCreator.swift
//  MyHealth
//
//  Created by Bao Bui on 1/24/24.
//

import Foundation
import UIKit
import PDFKit
import HealthKit
import SwiftUI

struct reportCategory {
    let title: String
    var dataTypes: [HKSampleType]
    var recentValue: [String]
    var maxValue: [String]
    var minValue: [String]
    var avgValue: [String]
    var data: [[HealthDataValue]]
}

class PDFCreator: NSObject {
    let dataTypes: Set<HKSampleType>?
    var categoryIndex: Int?
    let startTime: Date
    let endTime: Date
    let range: rangeOption
    
    init(dataTypes: Set<HKSampleType>, startTime: Date, endTime: Date, range: rangeOption) {
        self.dataTypes = dataTypes
        self.startTime = startTime
        self.endTime = endTime
        self.categoryIndex = nil
        self.range = range
    }
    
    init(category: Int, startTime: Date, endTime: Date, range: rangeOption) {
        self.startTime = startTime
        self.endTime = endTime
        self.categoryIndex = category
        self.dataTypes = nil
        self.range = range
    }
    
    func createPDF(_ completion: @escaping (Data) -> Void) {
        let pdfMetadata = [
            kCGPDFContextCreator: "My Health",
            kCGPDFContextAuthor: "HIVE",
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetadata as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // query for data
        
        var typeByCategory: [reportCategory] = []
        if let index = categoryIndex {
            let category = ViewModels.HealthCategories[index]
            var repCat = reportCategory(title: category.categoryName, dataTypes: [], recentValue: [], maxValue: [], minValue: [], avgValue: [], data: [])
            for type in category.dataTypes {
                if type.identifier != HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue {
                    repCat.dataTypes.append(type)
                    repCat.recentValue.append("")
                    repCat.maxValue.append("")
                    repCat.minValue.append("")
                    repCat.avgValue.append("")
                    repCat.data.append([])
                }
            }
            if !repCat.dataTypes.isEmpty {
                typeByCategory.append(repCat)
            }
        } 
        if let dataTypes = dataTypes {
            for category in ViewModels.HealthCategories {
                var repCat = reportCategory(title: category.categoryName, dataTypes: [], recentValue: [], maxValue: [], minValue: [], avgValue: [], data: [])
                for type in category.dataTypes {
                    if dataTypes.contains(where: {$0.identifier == type.identifier}) {
                        repCat.dataTypes.append(type)
                        repCat.recentValue.append("")
                        repCat.maxValue.append("")
                        repCat.minValue.append("")
                        repCat.avgValue.append("")
                        repCat.data.append([])
                    }
                }
                if !repCat.dataTypes.isEmpty {
                    typeByCategory.append(repCat)
                }
            }
        }
        
        let group = DispatchGroup()
        
        for j in 0..<typeByCategory.count {
            for i in 0..<typeByCategory[j].dataTypes.count {
                group.enter()
                let type = typeByCategory[j].dataTypes[i]
                let index = i
                getLastestData(type: type) { result in
                    typeByCategory[j].recentValue[index] = result
                    group.leave()
                }
                
                if type is HKQuantityType {
                    
                    group.enter()
                    performQuery(for: type.identifier, from: startTime, to: endTime) {results in
                        typeByCategory[j].data[i].append(contentsOf: results)
                        let filteredResults = results.compactMap({$0.value != 0 ? $0 : nil})
                        if filteredResults.isEmpty {
                            typeByCategory[j].maxValue[i] = "No Data"
                            typeByCategory[j].minValue[i] = "No Data"
                            typeByCategory[j].avgValue[i] = "No Data"
                            group.leave()
                            return
                        }
                        let min = filteredResults.min(by: {$0.value < $1.value})
                        let max = filteredResults.max(by: {$0.value < $1.value})
                        var avg: Double {
                            var total = 0.0
                            filteredResults.forEach({
                                total += $0.value
                            })
                            
                            return total / Double(filteredResults.count)
                        }
                        
                        var secondAvg: Double? {
                            let filteredResults = results.compactMap{$0.secondaryValue}
                            if filteredResults.isEmpty {
                                return nil
                            }
                            var total = 0.0
                            filteredResults.forEach({
                                total += $0
                            })
                            
                            return total / Double(filteredResults.count)
                        }
                        
                        var formatter : NumberFormatter {
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .decimal
                            formatter.maximumFractionDigits = 1
                            return formatter
                        }
                        
                        typeByCategory[j].maxValue[i] = "\(max!.displayString) \(getUnit(for: max!.identifier)!)"
                        typeByCategory[j].minValue[i] = "\(min!.displayString) \(getUnit(for: min!.identifier)!)"
                        
                        var avgString = formatter.string(from: avg as NSNumber) ?? "0.0"
                        avgString += secondAvg != nil ? "/\(formatter.string(from: secondAvg! as NSNumber) ?? "")" : ""
                        avgString += " \(getUnit(for: max!.identifier)!)"
                        
                        typeByCategory[j].avgValue[i] = avgString
                        group.leave()
                    }
                } else if type is HKCategoryType {
                    group.enter()
                    let healthStore = HealthData.healthStore
                    let predicate = HKQuery.predicateForSamples(withStart: startTime, end: endTime, options: [.strictEndDate, .strictStartDate])
                    let query = HKSampleQuery(sampleType: type,
                                              predicate: predicate,
                                              limit: HKObjectQueryNoLimit,
                                              sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)], resultsHandler: { query, result, error in
                        if let error = error {
                            print("Error fetching data for \(type.identifier): \(error.localizedDescription)")
                        } else {
                            if let result = result as? [HKCategorySample] {
                                let dataValues = result.compactMap({ element in
                                    let dataValue = categoryDataValue(identifier: type.identifier, from: element)
                                    
                                    if type.identifier == HKCategoryTypeIdentifier.menstrualFlow.rawValue {
                                        dataValue.metadata = [HKMetadataKeyMenstrualCycleStart: element.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool ?? false]
                                    }
                                    return dataValue
                                })
                                
                                typeByCategory[j].data[i].append(contentsOf: dataValues)
                            }
                        }
                        
                        group.leave()
                    })
                    
                    healthStore.execute(query)
                }
            }
        }
        
        group.notify(queue: .main) {
            
            
            DispatchQueue.main.async {
                let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
                
                let data = renderer.pdfData { (pdfContext) in
                    var pageNum = 0
                    for category in typeByCategory {
                        pdfContext.beginPage()
                        pageNum += 1
                        
                        let context = pdfContext.cgContext
                        
                        let headerHeight = self.addHeader(context: context, pageRect: pageRect)
                        
                        var currentBottom = self.addTitle(pageRect: pageRect, title: category.title, titleTop: headerHeight + 10)
                        let titleBottom = currentBottom + 5
                        currentBottom = self.addColumnTitles(pageRect: pageRect, titleTop: currentBottom + 5)
                        
                        self.addLine(context, pageRect: pageRect, location: currentBottom + 2)
                        if category.dataTypes.count == 0 {
                            
                        }
                        for i in 0..<category.dataTypes.count {
                            
                            
                            let width: CGFloat = pageRect.width / 2.0 - 30
                            let height: CGFloat = width / 2.0
                            
                            // add another page
                            if currentBottom + height + 50 > pageRect.height {
                                self.addMiddleLine(context, pageRect: pageRect, yStart: titleBottom, yEnd: currentBottom)
                                self.addFooter(pageRect: pageRect)
                                self.addPageNum(pageRect: pageRect, pageNum: pageNum)
                                
                                pdfContext.beginPage()
                                pageNum += 1
                                
                                let headerHeight = self.addHeader(context: context, pageRect: pageRect)
                                
                                currentBottom = self.addTitle(pageRect: pageRect, title: category.title, titleTop: headerHeight + 10)
                                let titleBottom = currentBottom + 5
                                currentBottom = self.addColumnTitles(pageRect: pageRect, titleTop: currentBottom + 5)
                                
                                self.addLine(context, pageRect: pageRect, location: currentBottom + 2)
                            }
                            
                            let type = category.dataTypes[i]
                            var currentRight: CGFloat
                            let top = currentBottom
                            (currentBottom, currentRight) = self.addTypeName(pageRect: pageRect, nameTop: currentBottom + 5, type: type)
                            
                            currentRight = self.addData(pageRect: pageRect, textLeft: currentRight, textTop: top+5, result: category.recentValue[i])
                            
                            if type is HKQuantityType {
                                let value = category.data[i] as? [quantityDataValue] ?? []
                                currentBottom = self.addQualityChart(context, pageRect: pageRect,
                                                                     data: value,
                                                                     location: CGPoint(x: currentRight + 10, y: top + 10))
                            } else if type is HKCategoryType {
                                let value = category.data[i] as? [categoryDataValue] ?? []
                                currentBottom = self.addCategoryChart(context, pageRect: pageRect,
                                                                      type: type, data: value,
                                                                      location: CGPoint(x: currentRight + 10, y: top + 10))
                            }
                        }
                        
                        self.addMiddleLine(context, pageRect: pageRect, yStart: titleBottom, yEnd: currentBottom)
                        self.addFooter(pageRect: pageRect)
                        self.addPageNum(pageRect: pageRect, pageNum: pageNum)
                    }
                }
                
                completion(data)
            }
        }
    }
    
    func addTitle(pageRect: CGRect, title: String, titleTop: CGFloat) -> CGFloat {
        let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: titleFont]
        let attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
        let titleStringSize = attributedTitle.size()
        let titleStringRect = CGRect(
            x: (pageRect.width - titleStringSize.width) / 2.0,
            y: titleTop,
            width: titleStringSize.width,
            height: titleStringSize.height)
        
        attributedTitle.draw(in: titleStringRect)
        return titleStringRect.origin.y + titleStringRect.size.height
    }
    
    func addTypeName(pageRect: CGRect, nameTop: CGFloat, type: HKSampleType) -> (bottom: CGFloat, right: CGFloat) {
        
        // Create Name
        let nameTextFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .natural
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let textAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: nameTextFont
        ]
        
        let attributedText = NSAttributedString(
            string: getDataTypeName(for: type.identifier)!,
            attributes: textAttributes)
        let attributedTextSize = attributedText.size()
        
        // Create Icon
        let imgHeight = attributedTextSize.height
        let imgWidth = attributedTextSize.height
        
        let imageRect = CGRect(x: 10, y: nameTop, width: imgWidth, height: imgHeight)
        let image = UIImage(systemName: getDataTypeIcon(for: type.identifier)!)?
            .withTintColor(getDataTypeColor(for: type.identifier)!, renderingMode: .alwaysTemplate)
            .resizeImage(to: CGSize(width: imgWidth, height: imgHeight))
        
        image?.draw(in: imageRect)
        
        let textRect = CGRect(
            x: 10 + imgWidth + 5,
            y: nameTop,
            width: pageRect.width / 3.0 - (10 + imgWidth + 5),
            height: attributedTextSize.height)
        attributedText.draw(in: textRect)
        
        return (nameTop + attributedTextSize.height, pageRect.width / 3.0)
    }
    
    func addData(pageRect: CGRect, textLeft: CGFloat, textTop: CGFloat, result: String) -> CGFloat {
        let textFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .natural
        textStyle.lineBreakMode = .byWordWrapping
        
        let textAttribute: [NSAttributedString.Key: Any]  = [
            NSAttributedString.Key.paragraphStyle: textStyle,
            NSAttributedString.Key.font: textFont
        ]
        
        let attributedText = NSAttributedString(
            string: result,
            attributes: textAttribute)
        let attributedTextSize = attributedText.size()
        let width = (pageRect.width * 2.0 / 3.0 - 5) / 4.0
        
        let textRect = CGRect(x: textLeft, y: textTop, width: width, height: attributedTextSize.height)
        
        attributedText.draw(in: textRect)
        
        return textLeft + width
    }
    
    func getLastestData(type: HKSampleType, _ completion: @escaping (String) -> Void) {
        let healthStore = HealthData.healthStore
        let datePredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: type, predicate: datePredicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { (query, results, error) in
            if let error = error {
                print("Error fetching data for \(type): \(error.localizedDescription)")
            } else {
                if let result = results?.first {
                    if let quantityType = type as? HKQuantityType {
                        let latestDate = result.startDate
                        let calendar = Calendar.current
                        
                        let startOfDay = calendar.startOfDay(for: latestDate)
                        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
                        performQuery(for: quantityType.identifier, from: startOfDay, to: endOfDay, range: self.range) { results in
                            if let result = results.first {
                                let text = "\(result.displayString) \(getUnit(for: quantityType.identifier)!)"
                                completion(text)
                            }
                        }
                    } else if let result = result as? HKCategorySample {
                        let dataValue = categoryDataValue(identifier: type.identifier,
                                                          startDate: result.startDate,
                                                          endDate: result.endDate, 
                                                          value: result.value)
                        
                        // Notification Event Types
                        if ViewModels.notificationType.contains(where: {$0 == type.identifier}) {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MMM dd, yyyy hh:mm"
                            
                            let text = formatter.string(from: result.startDate)
                            completion(text)
                        }
                        // Single Value Types
                        else if ViewModels.categoryValueType.contains(where: {$0 == type.identifier}) {
                            let current = Calendar.current
                            let start = current.startOfDay(for: result.startDate)
                            let end = current.date(bySettingHour: 23, minute: 59, second: 59, of: result.startDate)
                            let predicate = HKQuery.predicateForSamples(withStart: start,
                                                                        end: end,
                                                                        options: .strictStartDate)
                            let query = HKSampleQuery(sampleType: type,
                                                      predicate: predicate,
                                                      limit: HKObjectQueryNoLimit,
                                                      sortDescriptors: nil,
                                                      resultsHandler: {(query, results, error) in
                                if let error = error {
                                    print("error fetching data for \(type.identifier): \(error.localizedDescription)")
                                    completion("Error")
                                    return
                                } else if let results = results as? [HKCategorySample] {
                                    let time = self.totalTime(results.compactMap({
                                        categoryDataValue(identifier: type.identifier,
                                                          startDate: $0.startDate,
                                                          endDate: $0.endDate,
                                                          value: $0.value)
                                    }))
                                    
                                    let hr = Int(time / 3600)
                                    let min = Int((time % 3600) / 60)
                                    let sec = Int(time % 60)
                                    var text = ""
                                    if hr > 0 {
                                        text += "\(hr) hr "
                                    }
                                    if min > 0 {
                                        text += "\(min) min "
                                    }
                                    if sec > 0 {
                                        text += "\(sec) sec"
                                    }
                                    
                                    completion(text)
                                }
                            })
                            
                            healthStore.execute(query)
                        } 
                        // Sleep Analysis Type
                        else if type.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
                            let current = Calendar.current
                            let start: Date?
                            let end: Date?
                            let startOfDate = current.date(bySettingHour: 18, minute: 0, second: 0, of: dataValue.startDate)
                            if dataValue.startDate >= startOfDate! {
                                start = startOfDate
                                end = current.date(byAdding: .day, value: 1, to: start!)
                            } else {
                                end = startOfDate
                                start = current.date(byAdding: .day, value: -1, to: end!)
                            }
                            
                            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
                            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { (query, results, error) in
                                if let results = results as? [HKCategorySample] {
                                    let data = results.compactMap({categoryDataValue(identifier: type.identifier, from: $0)})
                                    let intervals = mergeTimeIntervals(data: data)
                                    
                                    var time: Int {
                                        var result = 0.0
                                        for (start, end) in intervals {
                                            result += end.timeIntervalSince(start)
                                        }
                                        
                                        return Int(result)
                                    }
                                    
                                    let hr = Int(time / 3600)
                                    let min = Int((time % 3600) / 60)
                                    let sec = Int(time % 60)
                                    var text = ""
                                    
                                    if hr > 0 {
                                        text += "\(hr) hr "
                                    }
                                    if min > 0 {
                                        text += "\(min) min "
                                    }
                                    if sec > 0 {
                                        text += "\(sec) sec"
                                    }
                                    
                                    completion(text)
                                }
                            })
                            
                            healthStore.execute(query)
                        }
                        // Symtoms, Horizontal Bar Chart
                        else {
                            let text = getCategoryValues(for: type.identifier)[dataValue.value]
                            completion(text)
                        }
                    }
                } else {
                    completion("No Data")
                }
            }
        }
        
        healthStore.execute(query)
    }
    func addColumnTitles(pageRect: CGRect, titleTop: CGFloat) -> CGFloat {
        let titleFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
        
        let attributedTypeColumn = NSAttributedString(string: "Data Type", attributes: titleAttributes)
        let attributedRecentColumn = NSAttributedString(string: "Most Recent", attributes: titleAttributes)
        
        let height = attributedTypeColumn.size().height
        let bigWidth = pageRect.width / 3.0 - 5
        let smallWidth = (pageRect.width - 10 - bigWidth) / 4.0
        
        let typeRect = CGRect(x: 5, y: titleTop, width: pageRect.width / 3.0 - 5, height: height)
        let recentRect = CGRect(x: 5+bigWidth, y: titleTop, width: smallWidth, height: height)
        
        attributedTypeColumn.draw(in: typeRect)
        attributedRecentColumn.draw(in: recentRect)
        
        addTimeRange(pageRect: pageRect, top: titleTop)
        
        return titleTop + height
    }
    func addLine(_ drawContext: CGContext, pageRect: CGRect, location: CGFloat) {
        drawContext.saveGState()
        drawContext.setLineWidth(1.0)
        
        drawContext.move(to: CGPoint(x: 5, y: location))
        drawContext.addLine(to: CGPoint(x: pageRect.width - 5, y: location))
        drawContext.strokePath()
        drawContext.restoreGState()
    }
    
    func addMiddleLine(_ drawContext: CGContext, pageRect: CGRect, yStart: CGFloat, yEnd: CGFloat) {
        drawContext.saveGState()
        drawContext.setLineWidth(1.0)
        
        drawContext.move(to: CGPoint(x: pageRect.width/2 - 10, y: yStart))
        drawContext.addLine(to: CGPoint(x: pageRect.width/2 - 10, y: yEnd))
        drawContext.strokePath()
        drawContext.restoreGState()
    }
    
    func addTimeRange(pageRect: CGRect, top: CGFloat) {
        let textFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let textAttributes: [NSAttributedString.Key: Any] = [.font : textFont]
        let attributedText = NSAttributedString(
            string: "For Data From \(dateIntervalToString(from: startTime, to: endTime))",
            attributes: textAttributes)
        
        let textSize = attributedText.size()
        let textRect = CGRect(
            x: pageRect.width / 2.0 + ((pageRect.width - 5) / 2.0 - textSize.width) / 2.0 - 5.0,
            y: top,
            width: textSize.width,
            height: textSize.height)
        attributedText.draw(in: textRect)
        
    }
    
    func addHeaderSpace(_ context: CGContext, pageRect: CGRect, height: CGFloat) {
        context.saveGState()
        context.setFillColor(CGColor(red: 173.0/255.0, green: 223.0/255.0, blue: 255.0/255.0, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: pageRect.width, height: height))
        context.restoreGState()
    }
    
    private func dateIntervalToString(from start: Date?, to end: Date?) -> String {
        let dateIntervalFormatter = DateIntervalFormatter()
        dateIntervalFormatter.dateStyle = .medium
        dateIntervalFormatter.timeStyle = .none
        
        return dateIntervalFormatter.string(from: start!, to: end!)
    }
    
    @MainActor
    func addQualityChart(_ context: CGContext,pageRect: CGRect, data:[quantityDataValue], location: CGPoint) -> CGFloat{
        let width: CGFloat = pageRect.width / 2.0 - 30
        let height: CGFloat = width / 2.0
        
        let chartFrame = CGRect(x: location.x, y: location.y,
                                width: width, height: height)
        let chart = PDFChart(data: data,
                             frame: chartFrame,
                             range: range)
        let renderer = ImageRenderer(content: chart)
        let image = renderer.uiImage
        image?.draw(in: chartFrame)
        
        return location.y + height
    }
    
    @MainActor
    func addCategoryChart(_ context: CGContext, pageRect: CGRect, type: HKSampleType, data: [categoryDataValue], location: CGPoint) -> CGFloat {
        let width: CGFloat = pageRect.width / 2.0 - 30
        let height: CGFloat = width / 2.0
        
        let chartFrame = CGRect(x: location.x, y: location.y, width: width, height: height)
        if type is HKCategoryType {
            if ViewModels.notificationType.contains(where: {$0 == type.identifier}) {
                // Implement notification type
            } else {
                if ViewModels.scatterChartType.contains(where: {$0 == type.identifier}) {
                    // Implement scatter type
                    let chart = PDFScatterChart(identifier: type.identifier,
                                                start: startTime,
                                                end: endTime,
                                                data: data,
                                                frame: chartFrame,
                                                range: range)
                    
                    let renderer = ImageRenderer(content: chart)
                    let image = renderer.uiImage
                    image?.draw(in: chartFrame)
                    
                } else {
                    if ViewModels.categoryValueType.contains(where: {$0 == type.identifier}) {
                        if range == .year {
                            let chart = PDFCateValueYearChart(identifier: type.identifier,
                                                              start: startTime,
                                                              end: endTime,
                                                              data: data,
                                                              frame: chartFrame)
                            
                            let renderer = ImageRenderer(content: chart)
                            let image = renderer.uiImage
                            image?.draw(in: chartFrame)
                            
                        } else {
                            let chart = PDFCateValueChart(identifier: type.identifier,
                                                          start: startTime,
                                                          end: endTime, data: data,
                                                          frame: chartFrame,
                                                          range: range)
                            
                            let renderer = ImageRenderer(content: chart)
                            let image = renderer.uiImage
                            image?.draw(in: chartFrame)
                        }
                    } else {
                        let chart = PDFHorBarChart(identifier: type.identifier,
                                                   start: startTime,
                                                   end: endTime,
                                                   data: data,
                                                   frame: chartFrame,
                                                   range: range)
                        
                        let renderer = ImageRenderer(content: chart)
                        let image = renderer.uiImage
                        image?.draw(in: chartFrame)
                    }
                }
            }
        }
        
        return location.y + height
    }
    
    func addHeader(context: CGContext, pageRect: CGRect) -> CGFloat {
        
        let userData = ViewModels.userData
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        
        let fieldFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let textFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        let fieldAttributes: [NSAttributedString.Key: Any] = [.font: fieldFont]
        let textAttributes: [NSAttributedString.Key: Any] = [.font: textFont]
        
        // Add name
        let attributedName = NSMutableAttributedString(string: "")
        
        var name: String {
            var res = ""
            if let firstName = userData.firstName {
                res = "\(firstName) "
            }
            
            if let lastName = userData.lastName {
                res += lastName
            }
            
            if res.isEmpty {
                return "No Data"
            } else {
                return res
            }
        }
        
        attributedName.append(NSAttributedString(string: "Name: ", attributes: fieldAttributes))
        attributedName.append(NSAttributedString(string: name, attributes: textAttributes))
        
        let nameSize = attributedName.size()
        // Add gender
        
        let attributedGender = NSMutableAttributedString(string: "")
        
        var gender: String {
            if let bioSex = userData.bioSex {
                return bioSex.rawValue
            } else {
                return "No Data"
            }
        }
        
        attributedGender.append(NSAttributedString(string: "Gender: ", attributes: fieldAttributes))
        attributedGender.append(NSAttributedString(string: gender, attributes: textAttributes))
        
        let genderSize = attributedGender.size()
        // Add birthday
        
        let attributedBirth = NSMutableAttributedString(string: "")
        
        var bDate: String {
            if let birthDate = userData.birthDate {
                return formatter.string(from: birthDate)
            } else {
                return "No Data"
            }
        }
        
        attributedBirth.append(NSAttributedString(string: "Birthday: ", attributes: fieldAttributes))
        attributedBirth.append(NSAttributedString(string: bDate, attributes: textAttributes))
        
        let birthDateSize = attributedBirth.size()
        // Add Profile picture??
        
        let imgWidth = nameSize.height + 10 + birthDateSize.height
        let pfpRect = CGRect(x: 5, y: 5, width: imgWidth, height: imgWidth)
        
        let group = DispatchGroup()
        group
            .enter()
        var pfpImg : UIImage? = nil
        let path = ViewModels.userData.imgPath
        ViewModels.getImageFromPath(path: path, completion: {image in
            pfpImg = image?.resizeImage(to: CGSize(width: imgWidth, height: imgWidth))
            group.leave()
        })
        
        // Add today date
        
        let attributedDate = NSMutableAttributedString(string: "")
        
        let date = formatter.string(from: Date())
        attributedDate.append(NSAttributedString(string: "Create on: ", attributes: fieldAttributes))
        attributedDate.append(NSAttributedString(string: date, attributes: textAttributes))
        let todaySize = attributedDate.size()
        
        let nameRect = CGRect(x: pfpRect.origin.x + imgWidth + 10, y: 5,
                              width: nameSize.width, height: nameSize.height)
        
        let bDayRect = CGRect(x: nameRect.origin.x,
                              y: nameRect.origin.y + nameRect.height + 5,
                              width: birthDateSize.width,
                              height: birthDateSize.height)
        
        let genderRect = CGRect(x: nameRect.origin.x + 175,
                                y: bDayRect.origin.y,
                                width: genderSize.width,
                                height: genderSize.height)
        
        let todayRect = CGRect(x: pageRect.width - todaySize.width - 10,
                               y: 5, width: todaySize.width, height: todaySize.height)
        
        let headerHeight = imgWidth + 15
        addHeaderSpace(context, pageRect: pageRect, height: headerHeight)
        
        attributedName.draw(in: nameRect)
        attributedBirth.draw(in: bDayRect)
        attributedGender.draw(in: genderRect)
        attributedDate.draw(in: todayRect)
        group.wait()
        pfpImg?.draw(in: pfpRect)
        return headerHeight
    }
    
    func addFooter(pageRect: CGRect) {
        let footer = "Created By: MyHealth from HIVE"
        let font = UIFont.systemFont(ofSize: 10, weight: .thin)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedString = NSAttributedString(string: footer, attributes: attributes)
        let stringSize = attributedString.size()
        
        let footerRect = CGRect(x: pageRect.width - stringSize.width - 10,
                                y: pageRect.height - stringSize.height - 10,
                                width: stringSize.width, height: stringSize.height)
        attributedString.draw(in: footerRect)
        
    }
    
    func addPageNum(pageRect: CGRect, pageNum: Int) {
        let font = UIFont.systemFont(ofSize: 10, weight: .thin)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attrPageNum = NSAttributedString(string: "\(pageNum)", attributes: attributes)
        let pageNumSize = attrPageNum.size()
        
        let pageNumRect = CGRect(x: (pageRect.width - pageNumSize.width) / 2.0,
                                 y: pageRect.height - pageNumSize.height - 10,
                                 width: pageNumSize.width, height: pageNumSize.height)
        attrPageNum.draw(in: pageNumRect)
    }
    
    func totalTime(_ data: [categoryDataValue]) -> Int {
        var sum = 0
        data.forEach({
            sum += Int($0.endDate.timeIntervalSince($0.startDate))
        })          
        return sum
    }
}

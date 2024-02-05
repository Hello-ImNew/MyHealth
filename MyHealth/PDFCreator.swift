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

struct reportCategory {
    let title: String
    var dataTypes: [HKSampleType]
    var recentValue: [String]
    var maxValue: [String]
    var minValue: [String]
    var avgValue: [String]
}

class PDFCreator: NSObject {
    let dataTypes: Set<HKSampleType>
    let startTime: Date
    let endTime: Date
    
    init(dataTypes: Set<HKSampleType>, startTime: Date, endTime: Date) {
        self.dataTypes = dataTypes
        self.startTime = startTime
        self.endTime = endTime
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
        
        for category in ViewModels.HealthCategories {
            var repCat = reportCategory(title: category.categoryName, dataTypes: [], recentValue: [], maxValue: [], minValue: [], avgValue: [])
            for type in category.dataTypes {
                if dataTypes.contains(where: {$0.identifier == type.identifier}) {
                    repCat.dataTypes.append(type)
                    repCat.recentValue.append("")
                    repCat.maxValue.append("")
                    repCat.minValue.append("")
                    repCat.avgValue.append("")
                }
            }
            if !repCat.dataTypes.isEmpty {
                typeByCategory.append(repCat)
            }
        }
        
        let group = DispatchGroup()
        
        for j in 0..<typeByCategory.count {
            for i in 0..<typeByCategory[j].dataTypes.count {
                group.enter()
                let index = i
                getLastestData(type: typeByCategory[j].dataTypes[i]) { result in
                    typeByCategory[j].recentValue[index] = result
                    group.leave()
                }
                
                group.enter()
                performQuery(for: typeByCategory[j].dataTypes[i].identifier, from: startTime, to: endTime) {results in
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
            }
        }
        
        group.notify(queue: .main) {
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
            
            let data = renderer.pdfData { (context) in
                
                for category in typeByCategory {
                    context.beginPage()
                    let context = context.cgContext
                    
                    self.addHeaderSpace(context, pageRect: pageRect, height: 50)
                    
                    var currentBottom = self.addTitle(pageRect: pageRect, title: category.title, titleTop: 55)
                    let titleBottom = currentBottom + 5
                    currentBottom = self.addTimeRange(pageRect: pageRect, top: currentBottom + 5)
                    currentBottom = self.addColumnTitles(pageRect: pageRect, titleTop: currentBottom + 5)
                    
                    self.addLine(context, pageRect: pageRect, location: currentBottom + 2)
                    
                    for i in 0..<category.dataTypes.count {
                        let type = category.dataTypes[i]
                        var currentRight: CGFloat
                        let top = currentBottom
                        (currentBottom, currentRight) = self.addTypeName(pageRect: pageRect, nameTop: currentBottom + 5, type: type)
                        
                        currentRight = self.addData(pageRect: pageRect, textLeft: currentRight, textTop: top+5, result: category.recentValue[i])
                        currentRight = self.addData(pageRect: pageRect, textLeft: currentRight, textTop: top+5, result: category.maxValue[i])
                        currentRight = self.addData(pageRect: pageRect, textLeft: currentRight, textTop: top+5, result: category.minValue[i])
                        currentRight = self.addData(pageRect: pageRect, textLeft: currentRight, textTop: top+5, result: category.avgValue[i])
                    }
                    
                    self.addMiddleLine(context, pageRect: pageRect, yStart: titleBottom, yEnd: currentBottom)
                }
            }
            
            completion(data)

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
                        performQuery(for: quantityType.identifier, from: startOfDay, to: endOfDay) { results in
                            if let result = results.first {
                                let text = "\(result.displayString) \(getUnit(for: quantityType.identifier)!)"
                                completion(text)
                            }
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
        let attributedMaxColumn = NSAttributedString(string: "Max", attributes: titleAttributes)
        let attributedMinColumn = NSAttributedString(string: "Min", attributes: titleAttributes)
        let attributedAverageColumn = NSAttributedString(string: "Average", attributes: titleAttributes)
        
        let height = attributedTypeColumn.size().height
        let bigWidth = pageRect.width / 3.0 - 5
        let smallWidth = (pageRect.width - 10 - bigWidth) / 4.0
        
        let typeRect = CGRect(x: 5, y: titleTop, width: pageRect.width / 3.0 - 5, height: height)
        let recentRect = CGRect(x: 5+bigWidth, y: titleTop, width: smallWidth, height: height)
        let maxRect = CGRect(x: 5+bigWidth+smallWidth, y: titleTop, width: smallWidth, height: height)
        let minRect = CGRect(x: 5+bigWidth+2*smallWidth, y: titleTop, width: smallWidth, height: height)
        let avgRect = CGRect(x: 5+bigWidth+3*smallWidth, y: titleTop, width: smallWidth, height: height)
        
        attributedTypeColumn.draw(in: typeRect)
        attributedRecentColumn.draw(in: recentRect)
        attributedMaxColumn.draw(in: maxRect)
        attributedMinColumn.draw(in: minRect)
        attributedAverageColumn.draw(in: avgRect)
        
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
    
    func addTimeRange(pageRect: CGRect, top: CGFloat) -> CGFloat {
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
        return textRect.origin.y + textRect.size.height
        
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
}

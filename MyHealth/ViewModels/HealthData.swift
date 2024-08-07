//
//  HealthData.swift
//  MyHealth
//
//  Created by Bao Bui on 9/22/23.
//

import Foundation
import HealthKit

enum myError: Error {
    case invalidArgument(String)
}

class HealthData {
    
    static let healthStore: HKHealthStore = HKHealthStore()
    
    // MARK: - Data Types
    
    static var readDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    static var shareDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    private static var allHealthDataTypes: [HKSampleType] {
        let typeIdentifiers: [String] = [
            HKQuantityTypeIdentifier.stepCount.rawValue,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
            HKQuantityTypeIdentifier.heartRate.rawValue,
            HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
            HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
            HKQuantityTypeIdentifier.distanceSwimming.rawValue,
            HKQuantityTypeIdentifier.flightsClimbed.rawValue,
            HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
            HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue,
            HKQuantityTypeIdentifier.respiratoryRate.rawValue
        ]
        
        return typeIdentifiers.compactMap { getSampleType(for: $0) }
    }
    
    class func requestHealthDataAccessIfNeeded(toShare shareTypes: Set<HKSampleType>?,
                                               read readTypes: Set<HKObjectType>?,
                                               completion: @escaping (_ success: Bool) -> Void) {
        if !HKHealthStore.isHealthDataAvailable() {
            fatalError("Health data is not available!")
        }
        
        print("Requesting HealthKit authorization...")
        
        if (shareTypes == nil || (shareTypes?.isEmpty ?? false))
            && (readTypes == nil || (readTypes?.isEmpty ?? false)) {
            print("No Data Types Requested.")
            completion(true)
            return
        }
        
        let share = shareTypes?.filter({!ViewModels.shareNotAllowedType.contains($0.identifier)})
        
        healthStore.requestAuthorization(toShare: share, read: readTypes) { (success, error) in
            if let error = error {
                print("requestAuthorization error:", error.localizedDescription)
            }
            
            if success {
                print("HealthKit authorization request was successful!")
            } else {
                print("HealthKit authorization was not successful.")
            }
            
            completion(success)
        }
    }
    
    class func saveHealthData(_ data: [HKObject], completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        healthStore.save(data, withCompletion: completion)
    }
}

func getSampleType(for identifier: String) -> HKSampleType? {
    if let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier)) {
        return quantityType
    }
    
    if let categoryType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier)) {
        return categoryType
    }
    
    return nil
}

func performQuery(for dataTypeIdentifier: String, from start: Date, to end: Date, range: rangeOption? = nil, _ completion: @escaping ([quantityDataValue]) -> Void) {
    let healthStore = HealthData.healthStore
    let current = Calendar.current
    let startQueryDate = current.startOfDay(for: start)
    let endQueryDate = current.date(bySettingHour: 23, minute: 59, second: 29, of: end)!
    
    let quantityType = HKQuantityType(HKQuantityTypeIdentifier(rawValue: dataTypeIdentifier))
    let predicate = HKQuery.predicateForSamples(withStart: startQueryDate, end: endQueryDate)
    let options = getStatisticsOptions(for: dataTypeIdentifier)
    let anchorDate = createAnchorDate(for: startQueryDate)
    let interval: DateComponents
    if range == .year {
        interval = DateComponents(month: 1)
    } else {
        interval = DateComponents(day: 1)
    }
    
    let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options, anchorDate: anchorDate, intervalComponents: interval)
    
    let updateInterfaceWithStaticstics: (HKStatisticsCollection) -> Void = {statisticsCollection in
        var dataValues: [quantityDataValue] = []
        
        let startDate = startQueryDate
        let endDate = endQueryDate
        
        statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
            let dataValue = quantityDataValue(identifier: dataTypeIdentifier,startDate: statistics.startDate, endDate: statistics.endDate, value: 0)
            if let quantity = getStatisticsQuantity(for: statistics, with: options),
               let unit: HKUnit = preferredUnit(for: dataTypeIdentifier) {
                dataValue.value = quantity.doubleValue(for: unit)
                if unit == .percent() {
                     dataValue.value *= 100
                }
                
                if range == .year && options == .cumulativeSum {
                    if statistics.startDate > Date() {
                        dataValue.value = 0
                    } else if let range = Calendar.current.range(of: .day, in: .month, for: statistics.startDate) {
                        if statistics.startDate.timeIntervalSinceNow < Double(range.count * 60 * 60 * 24) {
                            dataValue.value = dataValue.value / ceil(abs(statistics.startDate.timeIntervalSinceNow) / (60 * 60 * 24))
                        } else {
                            dataValue.value = dataValue.value / Double(range.count)
                        }
                    }
                }
            }
            dataValues.append(dataValue)
            
        }
        // if the datatype is boold pressure, get the diastolic value
        if dataTypeIdentifier == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue {
            let secondQuantityType = HKQuantityType(HKQuantityTypeIdentifier(rawValue: HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue))
            let secondOption = getStatisticsOptions(for: secondQuantityType.identifier)
            let secondQuery = HKStatisticsCollectionQuery(quantityType: secondQuantityType, quantitySamplePredicate: predicate, options: secondOption, anchorDate: anchorDate, intervalComponents: interval)
            let updateInterfaceWithSecondStatistics: (HKStatisticsCollection) -> Void = { statisticsCollection in
                var count = 0
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { (statistic, stop) in
                    if let quantity = getStatisticsQuantity(for: statistic, with: secondOption),
                        let unit = preferredUnit(for: secondQuantityType.identifier) {
                        dataValues[count].secondaryValue = quantity.doubleValue(for: unit)
                        if unit == .percent() {
                            dataValues[count].secondaryValue! *= 100
                        }
                    } else {
                        dataValues[count].secondaryValue = 0
                    }
                    count += 1
                }
                completion(dataValues)
            }
            
            secondQuery.initialResultsHandler = {query, statisticsCollection, error in
                if let statisticsCollection = statisticsCollection {
                    updateInterfaceWithSecondStatistics(statisticsCollection)
                }
            }
            
            healthStore.execute(secondQuery)
        } else {
            
            completion(dataValues)
        }
    }
    
    query.initialResultsHandler = { query, statisticsCollection, error in
        if let statisticsCollection = statisticsCollection {
            updateInterfaceWithStaticstics(statisticsCollection)
        }
    }
    
    healthStore.execute(query)
}


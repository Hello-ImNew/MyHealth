//
//  HealthKitSupport.swift
//  MyHealth
//
//  Created by Bao Bui on 9/25/23.
//

import Foundation
import HealthKit

/// Return an HKSampleType based on the input identifier that corresponds to an HKQuantityTypeIdentifier, HKCategoryTypeIdentifier
/// or other valid HealthKit identifier. Returns nil otherwise.
func getDataTypeName(for identifier: String) -> String? {
    var description: String?
    let sampleType = getSampleType(for: identifier)
    
    if sampleType is HKQuantityType {
        let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: identifier)
        
        switch quantityTypeIdentifier {
        case .stepCount:
            description = "Step Count"
        case .distanceWalkingRunning:
            description = "Distance Walking + Running"
        case .heartRate:
            description = "Heart Rate"
        case .activeEnergyBurned:
            description = "Active Energy Burned"
        case .basalEnergyBurned:
            description = "Resting Energy Burned"
        case .distanceSwimming:
            description = "Swimming Distance"
        case .flightsClimbed:
            description = "Flights Climbed"
        default:
            break
        }
    }
    
    return description
}

func getDataTypeIcon(for identifier: String) -> String? {
    var description: String?
    let sampleType = getSampleType(for: identifier)
    
    if sampleType is HKQuantityType {
        let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: identifier)
        
        switch quantityTypeIdentifier {
        case .stepCount, .distanceWalkingRunning:
            description = "figure.run"
        case .heartRate:
            description = "heart.fill"
        case .activeEnergyBurned, .basalEnergyBurned:
            description = "flame.fill"
        case .distanceSwimming:
            description = "figure.pool.swim"
        case .flightsClimbed:
            description = "figure.stairs"
        default:
            break
        }
    }
    
    return description
}

// MARK: - Unit Support
/// Return the appropriate unit to use with an HKSample based on the identifier. Asserts for compatible units.
func preferredUnit(for sample: HKSample) -> HKUnit? {
    let unit = preferredUnit(for: sample.sampleType.identifier, sampleType: sample.sampleType)
    
    if let quantitySample = sample as? HKQuantitySample, let unit = unit {
        assert(quantitySample.quantity.is(compatibleWith: unit),
               "The preferred unit is not compatiable with this sample.")
    }
    
    return unit
}

/// Returns the appropriate unit to use with an identifier corresponding to a HealthKit data type.
func preferredUnit(for sampleIdentifier: String) -> HKUnit? {
    return preferredUnit(for: sampleIdentifier, sampleType: nil)
}

private func preferredUnit(for identifier: String, sampleType: HKSampleType? = nil) -> HKUnit? {
    var unit: HKUnit?
    let sampleType = sampleType ?? getSampleType(for: identifier)
    
    if sampleType is HKQuantityType {
        let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: identifier)
        
        switch quantityTypeIdentifier {
        case .stepCount, .flightsClimbed:
            unit = .count()
        case .distanceWalkingRunning, .distanceSwimming:
            unit = .meter()
        case .heartRate:
            unit = HKUnit(from: "count/min")
        case .activeEnergyBurned, .basalEnergyBurned:
            unit = HKUnit(from: "kcal")
        default:
            break
        }
    }
    
    return unit
}

func getUnit(for sampleIdentifier: String) -> String? {
    let sampleType = getSampleType(for: sampleIdentifier)
    if sampleType is HKQuantityType {
        let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: sampleIdentifier)
        
        switch quantityTypeIdentifier {
        case .stepCount:
            return "Steps"
        case .distanceWalkingRunning, .distanceSwimming:
            return "Meters"
        case .heartRate:
            return "BPM"
        case .activeEnergyBurned, .basalEnergyBurned:
            return "Cal"
        case .flightsClimbed:
            return "Floors"
        default:
            break
        }
    }
    return nil
}

// MARK: - Query Support
func createAnchorDate(for date: Date) -> Date {
    let calendar: Calendar = .current
    var anchorComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: date)
    
    anchorComponents.hour = 2
    let anchorDate = calendar.date(from: anchorComponents)!
    return anchorDate
}

/// Return the most preferred `HKStatisticsOptions` for a data type identifier. Defaults to `.discreteAverage`.
func getStatisticsOptions(for dataTypeIdentifier: String) -> HKStatisticsOptions {
    var options: HKStatisticsOptions = .discreteAverage
    let sampleType = getSampleType(for: dataTypeIdentifier)
    
    if sampleType is HKQuantityType {
        let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: dataTypeIdentifier)
        
        switch quantityTypeIdentifier {
        case .stepCount, .distanceWalkingRunning, .activeEnergyBurned, .basalEnergyBurned, .distanceSwimming, .flightsClimbed:
            options = .cumulativeSum
        case .heartRate:
            options = .discreteAverage
        default:
            break
        }
    }
    
    return options
}

/// Return the statistics value in `statistics` based on the desired `statisticsOption`.
func getStatisticsQuantity(for statistics: HKStatistics, with statisticsOptions: HKStatisticsOptions) -> HKQuantity? {
    var statisticsQuantity: HKQuantity?
    
    switch statisticsOptions {
    case .cumulativeSum:
        statisticsQuantity = statistics.sumQuantity()
    case .discreteAverage:
        statisticsQuantity = statistics.averageQuantity()
    default:
        break
    }
    
    return statisticsQuantity
}


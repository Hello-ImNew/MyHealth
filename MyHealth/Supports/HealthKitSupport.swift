//
//  HealthKitSupport.swift
//  MyHealth
//
//  Created by Bao Bui on 9/25/23.
//

import Foundation
import HealthKit
import UIKit

/// Return an HKSampleType based on the input identifier that corresponds to an HKQuantityTypeIdentifier, HKCategoryTypeIdentifier
/// or other valid HealthKit identifier. Returns nil otherwise.
func getDataTypeName(for identifier: String) -> String? {
    var description: String?
    let sampleType = getSampleType(for: identifier)
    
    if sampleType is HKQuantityType {
        let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: identifier)
        
        switch quantityTypeIdentifier {
        case .stepCount:
            description = "Steps"
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
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            description = "Blood Pressure"
        case .respiratoryRate:
            description = "Respiratory Rate"
        case .runningPower:
            description = "Running Power"
        case .runningSpeed:
            description = "Running Speed"
        case .distanceCycling:
            description = "Cycling Distance"
        case .cyclingCadence:
            description = "Cycling Cadence"
        case .cyclingFunctionalThresholdPower:
            description = "Cycling Functional Threshold Power"
        case .cyclingPower:
            description = "Cycling Power"
        case .cyclingSpeed:
            description = "Cycling Speed"
        case .pushCount:
            description = "Pushes"
        case .distanceWheelchair:
            description = "Wheelchair Distance"
        case .swimmingStrokeCount:
            description = "Swimming Strokes"
        case .distanceSwimming:
            description = "Swimming Distance"
        case .underwaterDepth:
            description = "Underwater Depth"
        case .distanceDownhillSnowSports:
            description = "Downhill Snow Sports Distance"
        case .nikeFuel:
            description = "NikeFuel"
        case .physicalEffort:
            description = "Physical Effort"
        case .appleExerciseTime:
            description = "Exercise Minutes"
        case .appleMoveTime:
            description = "Move Minutes"
        case .appleStandTime:
            description = "Stand Time"
        case .environmentalAudioExposure:
            description = "Enviromental Sound Levels"
        case .environmentalSoundReduction:
            description = "Enviromental Sound Reduction"
        case .headphoneAudioExposure:
            description = "Headphone Audio Levels"
        case .atrialFibrillationBurden:
            description = "AFib History"
        case .heartRateRecoveryOneMinute:
            description = "Cardio Recovery"
        case .heartRateVariabilitySDNN:
            description = "Heart Rate Variability"
        case .peripheralPerfusionIndex:
            description = "PeripheralPerfusionIndex"
        case .restingHeartRate:
            description = "Resting Heart Rate"
        case .vo2Max:
            description = "Cardio Fitness"
        case . walkingHeartRateAverage:
            description = "Walking Heart Rate Average"
        case .appleWalkingSteadiness:
            description = "Walking Steadiness"
        case .runningGroundContactTime:
            description = "Ground Contact Time"
        case .runningStrideLength:
            description = "Running Stride Length"
        case .runningVerticalOscillation:
            description = "Vertical Oscillation"
        case .sixMinuteWalkTestDistance:
            description = "Six-Minute Walk"
        case .stairAscentSpeed:
            description = "Stair Speed: Up"
        case .stairDescentSpeed:
            description = "Stair Speed: Down"
        case .walkingAsymmetryPercentage:
            description = "Walking Asymmetry"
        case .walkingDoubleSupportPercentage:
            description = "Double Support Time"
        case .walkingSpeed:
            description = "Walking Speed"
        case .walkingStepLength:
            description = "Walking Step Length"
        case .dietaryBiotin:
            description = "Biotin"
        case .dietaryCaffeine:
            description = "Caffeine"
        case .dietaryCalcium:
            description = "Calcium"
        case .dietaryCarbohydrates:
            description = "CarbonHydrates"
        case .dietaryChloride:
            description = "Chloride"
        case .dietaryCholesterol:
            description = "Dietary Cholesterol"
        case .dietaryChromium:
            description = "Chromium"
        case .dietaryCopper:
            description = "Copper"
        case .dietaryEnergyConsumed:
            description = "Dietary Energy"
        case .dietarySugar:
            description = "Dietary Sugar"
        case .dietaryFatMonounsaturated:
            description = "Monounsaturated Fat"
        case .dietaryFatPolyunsaturated:
            description = "Polyunsaturated Fat"
        case .dietaryFatSaturated:
            description = "Saturated Fat"
        case .dietaryFatTotal:
            description = "Total Fat"
        case .dietaryFiber:
            description = "Fiber"
        case .dietaryFolate:
            description = "Folate"
        case .dietaryIodine:
            description = "Iodine"
        case .dietaryIron:
            description = "Iron"
        case .dietaryMagnesium:
            description = "Magnesium"
        case .dietaryManganese:
            description = "Manganese"
        case .dietaryMolybdenum:
            description = "Molybdenum"
        case .dietaryNiacin:
            description = "Niacin"
        case .dietaryPantothenicAcid:
            description = "Pantothenic Acid"
        case .dietaryPhosphorus:
            description = "Phosphorus"
        case .dietaryPotassium:
            description = "Potassium"
        case .dietaryProtein:
            description = "Protein"
        case .dietaryRiboflavin:
            description = "Riboflavin"
        case .dietarySelenium:
            description = "Selenium"
        case .dietarySodium:
            description = "Sodium"
        case .dietaryThiamin:
            description = "Thiamin"
        case .dietaryVitaminA:
            description = "Vitamin A"
        case .dietaryVitaminB6:
            description = "Vitamin B6"
        case .dietaryVitaminB12:
            description = "Vitamin B12"
        case .dietaryVitaminC:
            description = "Vitamin C"
        case .dietaryVitaminD:
            description = "Vitamin D"
        case .dietaryVitaminE:
            description = "Vitamin E"
        case .dietaryVitaminK:
            description = "Vitamin K"
        case .dietaryWater:
            description = "Water"
        case .dietaryZinc:
            description = "Zinc"
        case .basalBodyTemperature:
            description = "Balsal Body Tempature"
        case .height:
            description = "Height"
        case .bodyMass:
            description = "Weight"
        case .bodyMassIndex:
            description = "Body Mass Index"
        case .leanBodyMass:
            description = "Lean Body Mass"
        case .bodyFatPercentage:
            description = "Body Fat Percentage"
        case .waistCircumference:
            description = "Waist Circumference"
        case .appleSleepingWristTemperature:
            description = "Wrist Temperature"
        case .electrodermalActivity:
            description = "Electrothermal Activity"
        case .bodyTemperature:
            description = "Body Temperature"
        case .bloodAlcoholContent:
            description = "Blood Alcohol Content"
        case .numberOfAlcoholicBeverages:
            description = "Alcohol Consumption"
        case .insulinDelivery:
            description = "Insulin Delivery"
        case .numberOfTimesFallen:
            description = "Number of Times Fallen"
        case .timeInDaylight:
            description = "Time In Daylight"
        case .uvExposure:
            description = "UV Index"
        case .waterTemperature:
            description = "Water Temperature"
        case .forcedExpiratoryVolume1:
            description = "Force Expiratory Volume, 1 sec"
        case .forcedVitalCapacity:
            description = "Force Vital Capacity"
        case .inhalerUsage:
            description = "Inhaler Usage"
        case .oxygenSaturation:
            description = "Blood Oxygen"
        case .peakExpiratoryFlowRate:
            description = "Peak Expiratory Flow Rate"
        case .bloodGlucose:
            description = "Blood Glucose"
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
        case .appleSleepingWristTemperature,.electrodermalActivity, .waterTemperature, .basalBodyTemperature, .bodyTemperature:
            description = "waveform.path.ecg.rectangle"
        case .bodyFatPercentage, .bodyMass, .bodyMassIndex, .height, .leanBodyMass, .waistCircumference:
            description = "figure"
        case .activeEnergyBurned, .basalEnergyBurned, .appleExerciseTime, .appleMoveTime, .appleStandTime, .cyclingCadence, .cyclingFunctionalThresholdPower, .cyclingPower, .cyclingSpeed, .distanceCycling, .distanceDownhillSnowSports, .distanceSwimming, .distanceWalkingRunning, .distanceWheelchair, .flightsClimbed, .nikeFuel, .physicalEffort, .pushCount, .runningPower,. runningSpeed, .stepCount, .swimmingStrokeCount, .underwaterDepth:
            description = "flame.fill"
        case .environmentalAudioExposure, .environmentalSoundReduction, .headphoneAudioExposure:
            description = "ear"
        case .heartRate, .bloodPressureSystolic, .bloodPressureDiastolic, .atrialFibrillationBurden, .heartRateRecoveryOneMinute, .heartRateVariabilitySDNN, .peripheralPerfusionIndex, .restingHeartRate, .vo2Max, .walkingHeartRateAverage, .bloodAlcoholContent, .oxygenSaturation, .bloodGlucose:
            description = "heart.fill"
        case .appleWalkingSteadiness, .runningGroundContactTime, .runningStrideLength, .runningVerticalOscillation, .sixMinuteWalkTestDistance, .stairAscentSpeed, .stairDescentSpeed, .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage, .walkingSpeed, .walkingStepLength:
            description = "figure.walk.motion"
        case .dietaryBiotin, .dietaryCaffeine, .dietaryCalcium, .dietaryCarbohydrates, .dietaryChloride, .dietaryCholesterol, .dietaryChromium, .dietaryCopper, .dietaryEnergyConsumed, .dietaryFatMonounsaturated, .dietaryFatPolyunsaturated, .dietaryFatSaturated, .dietaryFatTotal, .dietaryFiber, .dietaryFolate, .dietaryIodine, .dietaryIron, .dietaryMagnesium, .dietaryManganese, .dietaryMolybdenum, .dietaryNiacin, .dietaryPantothenicAcid, .dietaryPhosphorus, .dietaryPotassium, .dietaryProtein, .dietaryRiboflavin, .dietarySelenium, .dietarySodium, .dietarySugar, .dietaryThiamin, .dietaryVitaminA, .dietaryVitaminB12, .dietaryVitaminB6, .dietaryVitaminC, .dietaryVitaminD, .dietaryVitaminE, .dietaryVitaminK, .dietaryWater, .dietaryZinc:
            description = "carrot"
        case .insulinDelivery, .numberOfAlcoholicBeverages, .numberOfTimesFallen, .timeInDaylight, .uvExposure:
            description = "cross.fill"
        case .respiratoryRate, .forcedExpiratoryVolume1, .forcedVitalCapacity, .inhalerUsage, .peakExpiratoryFlowRate:
            description = "lungs.fill"
        default:
            break
        }
    }
    
    return description
}

func getDataTypeColor(for identifier: String) -> UIColor? {
    var color: UIColor?
    let sampleType = getSampleType(for: identifier)
    
    if sampleType is HKQuantityType {
        let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: identifier)
        
        switch quantityTypeIdentifier {
        case .appleSleepingWristTemperature,.electrodermalActivity, .waterTemperature, .basalBodyTemperature, .bodyTemperature:
            color = .red
        case .bodyFatPercentage, .bodyMass, .bodyMassIndex, .height, .leanBodyMass, .waistCircumference:
            color = .purple
        case .activeEnergyBurned, .basalEnergyBurned, .appleExerciseTime, .appleMoveTime, .appleStandTime, .cyclingCadence, .cyclingFunctionalThresholdPower, .cyclingPower, .cyclingSpeed, .distanceCycling, .distanceDownhillSnowSports, .distanceSwimming, .distanceWalkingRunning, .distanceWheelchair, .flightsClimbed, .nikeFuel, .physicalEffort, .pushCount, .runningPower,. runningSpeed, .stepCount, .swimmingStrokeCount, .underwaterDepth:
            color = .orange
        case .environmentalAudioExposure, .environmentalSoundReduction, .headphoneAudioExposure:
            color = .blue
        case .heartRate, .bloodPressureSystolic, .bloodPressureDiastolic, .atrialFibrillationBurden, .heartRateRecoveryOneMinute, .heartRateVariabilitySDNN, .peripheralPerfusionIndex, .restingHeartRate, .vo2Max, .walkingHeartRateAverage, .bloodAlcoholContent, .oxygenSaturation, .bloodGlucose:
            color = .red
        case .appleWalkingSteadiness, .runningGroundContactTime, .runningStrideLength, .runningVerticalOscillation, .sixMinuteWalkTestDistance, .stairAscentSpeed, .stairDescentSpeed, .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage, .walkingSpeed, .walkingStepLength:
            color = .systemYellow
        case .dietaryBiotin, .dietaryCaffeine, .dietaryCalcium, .dietaryCarbohydrates, .dietaryChloride, .dietaryCholesterol, .dietaryChromium, .dietaryCopper, .dietaryEnergyConsumed, .dietaryFatMonounsaturated, .dietaryFatPolyunsaturated, .dietaryFatSaturated, .dietaryFatTotal, .dietaryFiber, .dietaryFolate, .dietaryIodine, .dietaryIron, .dietaryMagnesium, .dietaryManganese, .dietaryMolybdenum, .dietaryNiacin, .dietaryPantothenicAcid, .dietaryPhosphorus, .dietaryPotassium, .dietaryProtein, .dietaryRiboflavin, .dietarySelenium, .dietarySodium, .dietarySugar, .dietaryThiamin, .dietaryVitaminA, .dietaryVitaminB12, .dietaryVitaminB6, .dietaryVitaminC, .dietaryVitaminD, .dietaryVitaminE, .dietaryVitaminK, .dietaryWater, .dietaryZinc:
            color = .systemMint
        case .insulinDelivery, .numberOfAlcoholicBeverages, .numberOfTimesFallen, .timeInDaylight, .uvExposure:
            color = .blue
        case .respiratoryRate, .forcedExpiratoryVolume1, .forcedVitalCapacity, .inhalerUsage, .peakExpiratoryFlowRate:
            color = .cyan
        default:
            break
        }
    }
    
    return color
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
        case .stepCount, .flightsClimbed, .bodyMassIndex, .nikeFuel, .pushCount, .swimmingStrokeCount, .numberOfAlcoholicBeverages, .numberOfTimesFallen, .uvExposure, .inhalerUsage:
            unit = .count()
        case .respiratoryRate, .cyclingCadence, .heartRate, .heartRateRecoveryOneMinute, .restingHeartRate, .walkingHeartRateAverage:
            unit = HKUnit(from: "count/min")
        case .distanceWalkingRunning, .distanceSwimming, .height, .waistCircumference, .distanceCycling, .distanceDownhillSnowSports, .distanceWheelchair, .underwaterDepth, .runningStrideLength, .sixMinuteWalkTestDistance, .walkingStepLength:
            unit = .meter()
        case .runningVerticalOscillation:
            unit = .meterUnit(with: .centi)
        case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergyConsumed:
            unit = HKUnit(from: "kcal")
        case . bloodPressureSystolic, .bloodPressureDiastolic:
            unit = .millimeterOfMercury()
        case .appleSleepingWristTemperature, .waterTemperature, .basalBodyTemperature, .bodyTemperature:
            unit = .degreeCelsius()
        case .bodyFatPercentage, .atrialFibrillationBurden, .appleWalkingSteadiness, .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage, .bloodAlcoholContent, .oxygenSaturation, .peripheralPerfusionIndex:
            unit = .percent()
        case .electrodermalActivity:
            unit = .siemenUnit(with: .micro)
        case .appleExerciseTime, .appleMoveTime, .appleStandTime, .timeInDaylight:
            unit = .minute()
        case .cyclingFunctionalThresholdPower, .cyclingPower, .runningPower:
            unit = .watt()
        case .cyclingSpeed, .runningSpeed, .stairAscentSpeed, .stairDescentSpeed, .walkingSpeed:
            unit = HKUnit(from: "m/s")
        case .physicalEffort:
            unit = HKUnit(from: "kcal/(kg*hr)")
        case .environmentalAudioExposure, .environmentalSoundReduction, .headphoneAudioExposure:
            unit = .decibelAWeightedSoundPressureLevel()
        case .heartRateVariabilitySDNN, .runningGroundContactTime:
            unit = .secondUnit(with: .milli)
        case .vo2Max:
            unit = HKUnit(from: "ml/(kg*min)")
        case .bodyMass, .leanBodyMass:
            unit = .gramUnit(with: .kilo)
        case .dietaryCarbohydrates, .dietarySugar, .dietaryFiber, .dietaryFatMonounsaturated, .dietaryFatPolyunsaturated, .dietaryProtein, .dietaryFatSaturated, .dietaryFatTotal:
            unit = .gram()
        case .dietaryBiotin, .dietaryChromium, .dietaryFolate, .dietaryIodine, .dietaryMolybdenum, .dietarySelenium, .dietaryVitaminA, .dietaryVitaminD, .dietaryVitaminK, .dietaryVitaminB12:
            unit = .gramUnit(with: .micro)
        case .dietaryCaffeine, .dietaryCalcium, .dietaryChloride, .dietaryCopper, .dietaryCholesterol, .dietaryIron, .dietaryMagnesium, .dietaryManganese, .dietaryNiacin, .dietaryPantothenicAcid, .dietaryPhosphorus, .dietaryPotassium, .dietaryRiboflavin, .dietarySodium, .dietaryThiamin, .dietaryVitaminB6, .dietaryVitaminC, . dietaryVitaminE, .dietaryZinc:
            unit = .gramUnit(with: .milli)
        case .dietaryWater:
            unit = .literUnit(with: .milli)
        case .forcedExpiratoryVolume1, .forcedVitalCapacity:
            unit = .liter()
        case .insulinDelivery:
            unit = .internationalUnit()
        case .peakExpiratoryFlowRate:
            unit = HKUnit(from: "L/min")
        case .bloodGlucose:
            unit = HKUnit(from: "mg/dL")
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
        
        case .cyclingCadence:
            return "RPM"
        case .appleExerciseTime, .appleMoveTime, .appleStandTime, .timeInDaylight:
            return "Min"
        case .heartRateVariabilitySDNN, .runningGroundContactTime:
            return "ms"
        case .stepCount:
            return "Steps"
        case .distanceWalkingRunning, .distanceSwimming, .height, .waistCircumference, .distanceCycling, .distanceDownhillSnowSports, .distanceWheelchair, .underwaterDepth, .runningStrideLength, .sixMinuteWalkTestDistance, .walkingStepLength:
            return "Meters"
        case .runningVerticalOscillation:
            return "cm"
        case .bodyMass, .leanBodyMass:
            return "kg"
        case .dietaryCarbohydrates, .dietarySugar, .dietaryFiber, .dietaryFatMonounsaturated, .dietaryFatPolyunsaturated, .dietaryProtein, .dietaryFatSaturated, .dietaryFatTotal:
            return "g"
        case .dietaryCaffeine, .dietaryCalcium, .dietaryChloride, .dietaryCopper, .dietaryCholesterol, .dietaryIron, .dietaryMagnesium, .dietaryManganese, .dietaryNiacin, .dietaryPantothenicAcid, .dietaryPhosphorus, .dietaryPotassium, .dietaryRiboflavin, .dietarySodium, .dietaryThiamin, .dietaryVitaminB6, .dietaryVitaminC, . dietaryVitaminE, .dietaryZinc:
            return "mg"
        case .dietaryBiotin, .dietaryChromium, .dietaryFolate, .dietaryIodine, .dietaryMolybdenum, .dietarySelenium, .dietaryVitaminA, .dietaryVitaminD, .dietaryVitaminK, .dietaryVitaminB12:
            return "mcg"
        case .heartRate, .heartRateRecoveryOneMinute, .walkingHeartRateAverage, .restingHeartRate:
            return "BPM"
        case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergyConsumed:
            return "Cal"
        case .flightsClimbed:
            return "Floors"
        case .bloodPressureSystolic:
            return "mmHg"
        case .respiratoryRate:
            return "breaths/min"
        case .nikeFuel:
            return "Points"
        case .bodyMassIndex:
            return "BMI"
        case .pushCount:
            return "Pushes"
        case .swimmingStrokeCount:
            return "Strokes"
        case .numberOfAlcoholicBeverages:
            return "Drinks"
        case .numberOfTimesFallen:
            return "Times"
        case .appleSleepingWristTemperature, .waterTemperature, .basalBodyTemperature, .bodyTemperature:
            return "°C"
        case .bodyFatPercentage, .atrialFibrillationBurden, .appleWalkingSteadiness, .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage, .bloodAlcoholContent, .oxygenSaturation:
            return "%"
        case .electrodermalActivity:
            return "mcS"
        case .cyclingFunctionalThresholdPower, .cyclingPower, .runningPower:
            return "W"
        case .cyclingSpeed, .runningSpeed, .stairAscentSpeed, .stairDescentSpeed, .walkingSpeed:
            return "m/s"
        case .physicalEffort:
            return "METs"
        case .environmentalAudioExposure, .environmentalSoundReduction, .headphoneAudioExposure:
            return "dB"
        case .vo2Max:
            return "VO2max"
        case .dietaryWater:
            return "mL"
        case .forcedExpiratoryVolume1, .forcedVitalCapacity:
            return "L"
        case .insulinDelivery:
            return "Units"
        case .peakExpiratoryFlowRate:
            return "L/min"
        case .bloodGlucose:
            return "mg/dL"
        case .uvExposure, .inhalerUsage:
            return ""
        default:
            break
        }
    }
    return nil
}

// MARK: - Query Support
func createAnchorDate(for date: Date) -> Date {
    let calendar: Calendar = .current
    let anchorDate = calendar.startOfDay(for: date)
    return anchorDate
}

/// Return the most preferred `HKStatisticsOptions` for a data type identifier. Defaults to `.discreteAverage`.
func getStatisticsOptions(for dataTypeIdentifier: String) -> HKStatisticsOptions {
    var options: HKStatisticsOptions = .discreteAverage
    let sampleType = getSampleType(for: dataTypeIdentifier)
    
    if sampleType is HKQuantityType {
        let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: dataTypeIdentifier)
        
        switch quantityTypeIdentifier {
        case .stepCount, .distanceWalkingRunning, .activeEnergyBurned, .basalEnergyBurned, .distanceSwimming, .flightsClimbed, .appleExerciseTime, .appleMoveTime, .appleStandTime, .distanceCycling, .distanceDownhillSnowSports, .distanceWheelchair, .nikeFuel, .pushCount, .swimmingStrokeCount, .dietaryBiotin, .dietaryCaffeine, .dietaryCalcium, .dietaryCarbohydrates, .dietaryChloride, .dietaryCholesterol, .dietaryChromium, .dietaryCopper, .dietaryEnergyConsumed, .dietaryFatMonounsaturated, .dietaryFatPolyunsaturated, .dietaryFatSaturated, .dietaryFatTotal, .dietaryFiber, .dietaryIodine, .dietaryIron, .dietaryMagnesium, .dietaryManganese, .dietaryMolybdenum, .dietaryNiacin, .dietaryPantothenicAcid, .dietaryPhosphorus, .dietaryPotassium, .dietaryProtein, .dietaryRiboflavin, .dietarySelenium, .dietarySodium, .dietarySugar, .dietaryThiamin, .dietaryVitaminA, .dietaryVitaminB6, .dietaryVitaminB12, .dietaryVitaminC, .dietaryVitaminD, .dietaryVitaminE, .dietaryVitaminK, .dietaryWater, .dietaryZinc, .insulinDelivery, .numberOfAlcoholicBeverages, .numberOfTimesFallen, .timeInDaylight, .inhalerUsage:
            options = .cumulativeSum
        case .heartRate, .bloodPressureSystolic, .bloodPressureDiastolic, .respiratoryRate, .appleSleepingWristTemperature, .bodyFatPercentage, .bodyMass, .bodyMassIndex, .electrodermalActivity, .height, .leanBodyMass, .waistCircumference, .cyclingCadence, .cyclingFunctionalThresholdPower, .cyclingPower, .cyclingSpeed, .physicalEffort, .runningPower, .runningSpeed, .underwaterDepth, .environmentalAudioExposure, .environmentalSoundReduction, .headphoneAudioExposure, .atrialFibrillationBurden, .heartRateRecoveryOneMinute, .heartRateVariabilitySDNN, .peripheralPerfusionIndex, .restingHeartRate, .vo2Max, .walkingHeartRateAverage, .appleWalkingSteadiness, .runningGroundContactTime, .runningStrideLength, .runningVerticalOscillation, .sixMinuteWalkTestDistance, .stairAscentSpeed, .stairDescentSpeed, .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage, .walkingSpeed, .walkingStepLength, .bloodAlcoholContent, .uvExposure, .waterTemperature, .basalBodyTemperature, .forcedExpiratoryVolume1, .forcedVitalCapacity, .oxygenSaturation, .peakExpiratoryFlowRate, .bloodGlucose, .bodyTemperature:
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

func processHealthSample(for typeIdentifier: String, value: Double, date: Date) -> HKObject? {
    guard
        let sampleType = getSampleType(for: typeIdentifier)
    else {
        return nil
    }
    
    let unit = preferredUnit(for: typeIdentifier)!
    
    let start = date
    let end = date
    
    var optionalSample: HKObject?
    if let quantityType = sampleType as? HKQuantityType {
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let quantitySample = HKQuantitySample(type: quantityType, quantity: quantity, start: start, end: end)
        optionalSample = quantitySample
    }
    if let categoryType = sampleType as? HKCategoryType {
        let categorySample = HKCategorySample(type: categoryType, value: Int(value), start: start, end: end)
        optionalSample = categorySample
    }
    return optionalSample
}

func isAllowedShared(for type: String) -> Bool {
    return !ViewModels.shareNotAllowedType.contains(type)
}

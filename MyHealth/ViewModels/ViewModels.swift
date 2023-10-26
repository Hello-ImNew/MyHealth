//
//  ViewModels.swift
//  MyHealth
//
//  Created by Bao Bui on 10/19/23.
//

import Foundation
import HealthKit
import UIKit

class ViewModels {
    static var healthCategories: [HealthCategory] {
        var activity: HealthCategory {
            var activityTypes: [HKSampleType] {
                let identifiers: [String] = [
                    HKQuantityTypeIdentifier.stepCount.rawValue,
                    HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
                    HKQuantityTypeIdentifier.runningPower.rawValue,
                    HKQuantityTypeIdentifier.runningSpeed.rawValue,
                    HKQuantityTypeIdentifier.distanceCycling.rawValue,
                    HKQuantityTypeIdentifier.cyclingCadence.rawValue,
                    HKQuantityTypeIdentifier.cyclingFunctionalThresholdPower.rawValue,
                    HKQuantityTypeIdentifier.cyclingPower.rawValue,
                    HKQuantityTypeIdentifier.cyclingSpeed.rawValue,
                    HKQuantityTypeIdentifier.pushCount.rawValue,
                    HKQuantityTypeIdentifier.distanceWheelchair.rawValue,
                    HKQuantityTypeIdentifier.swimmingStrokeCount.rawValue,
                    HKQuantityTypeIdentifier.distanceSwimming.rawValue,
                    HKQuantityTypeIdentifier.underwaterDepth.rawValue,
                    HKQuantityTypeIdentifier.distanceDownhillSnowSports.rawValue,
                    HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
                    HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
                    HKQuantityTypeIdentifier.flightsClimbed.rawValue,
                    HKQuantityTypeIdentifier.nikeFuel.rawValue,
                    HKQuantityTypeIdentifier.physicalEffort.rawValue,
                    HKQuantityTypeIdentifier.appleExerciseTime.rawValue,
                    HKQuantityTypeIdentifier.appleMoveTime.rawValue,
                    HKQuantityTypeIdentifier.appleStandTime.rawValue
                ]
                
                return identifiers.compactMap { getSampleType(for: $0) }
            }
            let color: UIColor = .systemOrange
            return HealthCategory(categoryName: "Activity", dataTypes: activityTypes, icon: "flame.fill", color: color)
        }
        
        var hearingHealth: HealthCategory {
            var hearingHealthTypes: [HKSampleType] {
                let identifiers: [String] = [
                    HKQuantityTypeIdentifier.environmentalAudioExposure.rawValue,
                    HKQuantityTypeIdentifier.environmentalSoundReduction.rawValue,
                    HKQuantityTypeIdentifier.headphoneAudioExposure.rawValue
                ]
                
                return identifiers.compactMap { getSampleType(for: $0) }
            }
            let color : UIColor = .blue
            
            return HealthCategory(categoryName: "Hearing", dataTypes: hearingHealthTypes, icon: "ear", color: color)
        }
        
        var heart: HealthCategory {
            var heartTypes: [HKSampleType] {
                let identifiers: [String] = [
                    HKQuantityTypeIdentifier.heartRate.rawValue,
                    HKQuantityTypeIdentifier.atrialFibrillationBurden.rawValue,
                    HKQuantityTypeIdentifier.heartRateRecoveryOneMinute.rawValue,
                    HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue,
                    HKQuantityTypeIdentifier.peripheralPerfusionIndex.rawValue,
                    HKQuantityTypeIdentifier.restingHeartRate.rawValue,
                    HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
                    HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue,
                    HKQuantityTypeIdentifier.vo2Max.rawValue,
                    HKQuantityTypeIdentifier.walkingHeartRateAverage.rawValue
                ]
                
                return identifiers.compactMap {getSampleType(for: $0)}
            }
            let color : UIColor = .red
            
            return HealthCategory(categoryName: "Heart", dataTypes: heartTypes, icon: "heart.fill", color: color)
        }
        
        var mobility : HealthCategory {
            var mobilityTypes: [HKSampleType] {
                let identifiers: [String] = [
                    HKQuantityTypeIdentifier.appleWalkingSteadiness.rawValue,
                    HKQuantityTypeIdentifier.runningGroundContactTime.rawValue,
                    HKQuantityTypeIdentifier.runningStrideLength.rawValue,
                    HKQuantityTypeIdentifier.runningVerticalOscillation.rawValue,
                    HKQuantityTypeIdentifier.sixMinuteWalkTestDistance.rawValue,
                    HKQuantityTypeIdentifier.stairAscentSpeed.rawValue,
                    HKQuantityTypeIdentifier.stairDescentSpeed.rawValue,
                    HKQuantityTypeIdentifier.walkingAsymmetryPercentage.rawValue,
                    HKQuantityTypeIdentifier.walkingDoubleSupportPercentage.rawValue,
                    HKQuantityTypeIdentifier.walkingSpeed.rawValue,
                    HKQuantityTypeIdentifier.walkingStepLength.rawValue
                ]
                return identifiers.compactMap {getSampleType(for: $0)}
            }
            
            return HealthCategory(categoryName: "Mobility", dataTypes: mobilityTypes, icon: "figure.walk.motion", color: .orange)
        }
        
        var nutrition: HealthCategory {
            var nutritionTypes: [HKSampleType] {
                let identifiers = [
                    HKQuantityTypeIdentifier.dietaryBiotin.rawValue,
                    HKQuantityTypeIdentifier.dietaryCaffeine.rawValue,
                    HKQuantityTypeIdentifier.dietaryCalcium.rawValue,
                    HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue,
                    HKQuantityTypeIdentifier.dietaryChloride.rawValue,
                    HKQuantityTypeIdentifier.dietaryChromium.rawValue,
                    HKQuantityTypeIdentifier.dietaryCopper.rawValue,
                    HKQuantityTypeIdentifier.dietaryCholesterol.rawValue,
                    HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue,
                    HKQuantityTypeIdentifier.dietarySugar.rawValue,
                    HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue,
                    HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue,
                    HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue,
                    HKQuantityTypeIdentifier.dietaryFatTotal.rawValue,
                    HKQuantityTypeIdentifier.dietaryFiber.rawValue,
                    HKQuantityTypeIdentifier.dietaryFolate.rawValue,
                    HKQuantityTypeIdentifier.dietaryIodine.rawValue,
                    HKQuantityTypeIdentifier.dietaryIron.rawValue,
                    HKQuantityTypeIdentifier.dietaryMagnesium.rawValue,
                    HKQuantityTypeIdentifier.dietaryManganese.rawValue,
                    HKQuantityTypeIdentifier.dietaryMolybdenum.rawValue,
                    HKQuantityTypeIdentifier.dietaryNiacin.rawValue,
                    HKQuantityTypeIdentifier.dietaryPantothenicAcid.rawValue,
                    HKQuantityTypeIdentifier.dietaryPhosphorus.rawValue,
                    HKQuantityTypeIdentifier.dietaryPotassium.rawValue,
                    HKQuantityTypeIdentifier.dietaryProtein.rawValue,
                    HKQuantityTypeIdentifier.dietaryRiboflavin.rawValue,
                    HKQuantityTypeIdentifier.dietarySelenium.rawValue,
                    HKQuantityTypeIdentifier.dietarySodium.rawValue,
                    HKQuantityTypeIdentifier.dietaryThiamin.rawValue,
                    HKQuantityTypeIdentifier.dietaryVitaminA.rawValue,
                    HKQuantityTypeIdentifier.dietaryVitaminB6.rawValue,
                    HKQuantityTypeIdentifier.dietaryVitaminB12.rawValue,
                    HKQuantityTypeIdentifier.dietaryVitaminC.rawValue,
                    HKQuantityTypeIdentifier.dietaryVitaminD.rawValue,
                    HKQuantityTypeIdentifier.dietaryVitaminE.rawValue,
                    HKQuantityTypeIdentifier.dietaryVitaminK.rawValue,
                    HKQuantityTypeIdentifier.dietaryWater.rawValue,
                    HKQuantityTypeIdentifier.dietaryZinc.rawValue
                ]
                
                return identifiers.compactMap {getSampleType(for: $0)}
            }
            return HealthCategory(categoryName: "Nutrition", dataTypes: nutritionTypes, icon: "carrot", color: .systemMint)
        }
        
        var bodyMeasurement: HealthCategory {
            var bodyMeasurementTypes: [HKSampleType] {
                let identifiers : [String] = [
                    HKQuantityTypeIdentifier.height.rawValue,
                    HKQuantityTypeIdentifier.bodyMass.rawValue,
                    HKQuantityTypeIdentifier.bodyMassIndex.rawValue,
                    HKQuantityTypeIdentifier.leanBodyMass.rawValue,
                    HKQuantityTypeIdentifier.bodyFatPercentage.rawValue,
                    HKQuantityTypeIdentifier.waistCircumference.rawValue,
                    HKQuantityTypeIdentifier.basalBodyTemperature.rawValue,
                    HKQuantityTypeIdentifier.appleSleepingWristTemperature.rawValue,
                    HKQuantityTypeIdentifier.electrodermalActivity.rawValue,
                    HKQuantityTypeIdentifier.bodyTemperature.rawValue
                ]
                
                return identifiers.compactMap { getSampleType(for: $0)}
            }
            
            return HealthCategory(categoryName: "Body Measurements", dataTypes: bodyMeasurementTypes, icon: "figure", color: .purple)
        }
        
        var other: HealthCategory {
            var otherTypes: [HKSampleType] {
                let identifiers: [String] = [
                    HKQuantityTypeIdentifier.bloodAlcoholContent.rawValue,
                    HKQuantityTypeIdentifier.numberOfAlcoholicBeverages.rawValue,
                    HKQuantityTypeIdentifier.insulinDelivery.rawValue,
                    HKQuantityTypeIdentifier.numberOfTimesFallen.rawValue,
                    HKQuantityTypeIdentifier.timeInDaylight.rawValue,
                    HKQuantityTypeIdentifier.uvExposure.rawValue,
                    HKQuantityTypeIdentifier.waterTemperature.rawValue
                ]
                
                return identifiers.compactMap {getSampleType(for: $0)}
            }
            
            return HealthCategory(categoryName: "Other Data", dataTypes: otherTypes, icon: "cross.fill", color: .blue)
        }
        
        var respiratory: HealthCategory {
            var repiratoryTypes: [HKSampleType] {
                let identifiers: [String] = [
                    HKQuantityTypeIdentifier.forcedExpiratoryVolume1.rawValue,
                    HKQuantityTypeIdentifier.forcedVitalCapacity.rawValue,
                    HKQuantityTypeIdentifier.inhalerUsage.rawValue,
                    HKQuantityTypeIdentifier.peakExpiratoryFlowRate.rawValue,
                    HKQuantityTypeIdentifier.respiratoryRate.rawValue,
                    HKQuantityTypeIdentifier.oxygenSaturation.rawValue,
                    HKQuantityTypeIdentifier.vo2Max.rawValue,
                    HKQuantityTypeIdentifier.sixMinuteWalkTestDistance.rawValue
                ]
                
                return identifiers.compactMap {getSampleType(for: $0)}
            }
            
            return HealthCategory(categoryName: "Respiratory", dataTypes: repiratoryTypes, icon: "lungs.fill", color: .cyan)
        }
        
        var vitalSign: HealthCategory {
            var vitalSignTypes: [HKSampleType] {
                let identifiers: [String] = [
                    HKQuantityTypeIdentifier.bodyTemperature.rawValue,
                    HKQuantityTypeIdentifier.bloodGlucose.rawValue,
                    HKQuantityTypeIdentifier.oxygenSaturation.rawValue,
                    HKQuantityTypeIdentifier.heartRate.rawValue,
                    HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
                    HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue,
                    HKQuantityTypeIdentifier.respiratoryRate.rawValue
                ]
                
                return identifiers.compactMap {getSampleType(for: $0)}
            }
            
            return HealthCategory(categoryName: "Vitals", dataTypes: vitalSignTypes, icon: "waveform.path.ecg.rectangle", color: .red)
        }
        
        return [activity, bodyMeasurement, hearingHealth, heart, nutrition, mobility, respiratory, vitalSign, other]
    }
    
    static var shareNotAllowedType: [String] {
        return [
            HKQuantityTypeIdentifier.nikeFuel.rawValue,
            HKQuantityTypeIdentifier.appleMoveTime.rawValue,
            HKQuantityTypeIdentifier.appleExerciseTime.rawValue,
            HKQuantityTypeIdentifier.appleStandTime.rawValue,
            HKQuantityTypeIdentifier.appleSleepingWristTemperature.rawValue,
            HKQuantityTypeIdentifier.appleWalkingSteadiness.rawValue,
            HKQuantityTypeIdentifier.walkingHeartRateAverage.rawValue,
            HKQuantityTypeIdentifier.atrialFibrillationBurden.rawValue,
            HKQuantityTypeIdentifier.walkingAsymmetryPercentage.rawValue
        ]
    }
}

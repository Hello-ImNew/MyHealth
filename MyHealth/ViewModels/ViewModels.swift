//
//  ViewModels.swift
//  MyHealth
//
//  Created by Bao Bui on 10/19/23.
//

import Foundation
import HealthKit
import UIKit
import CoreData

class ViewModels {
    
    // MARK: Favorite data types
    private static let userDefaults = UserDefaults.standard
    
    private static let healthTypesKey = "healthTypes"
    private static let userDataKey = "userData"
    private static let userIDKey = "user_ID"
    private static let savedAccountKey = "SavedAccount"
    
    static var favHealthTypes: [String] = []
//    {
//        let healthTypes: [String] = userDefaults.object(forKey: healthTypesKey) as? [String] ?? []
//        
//        return healthTypes
//    }
    
    static var favDataType: [HKSampleType] {
        return favHealthTypes.compactMap({ getSampleType(for: $0)})
    }
    
    static func removeFavHealthType(for healthType: String) {
        favHealthTypes.removeAll(where: {$0 == healthType})
        var healthTypes = favHealthTypes
        healthTypes.removeAll(where: {
            $0 == healthType
        })
        userDefaults.set(healthTypes, forKey: healthTypesKey)
        userDefaults.synchronize()
        
        let link = serviceURL + "remove_fav_data.php"
        
        guard let url = URL(string: link) else {
            print("Error connect to web service.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = [
                "user_ID": ViewModels.userID!,
                "type": healthType
            ]
            
            let jsondata = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsondata
        } catch {
            print("Error encoding data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil,
                  let data = data else {
                print("Error: \(error!)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                  print("Server error")
                  print(String(data: data, encoding: .utf8) ?? "" )
                return
              }
            
            print("Save success.")
        }.resume()
    }
    
    static func addFavHealthType(for healthType: String) {
        if !favHealthTypes.contains(healthType) {
            favHealthTypes.append(healthType)
        }
        
        var healthTypes = favHealthTypes
        healthTypes.append(healthType)
        userDefaults.set(healthTypes, forKey: healthTypesKey)
        userDefaults.synchronize()
        
        let link = serviceURL + "add_fav_data.php"
        
        guard let url = URL(string: link) else {
            print("Error connect to web service.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = [
                "user_ID": ViewModels.userID!,
                "type": healthType
            ]
            
            let jsondata = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsondata
        } catch {
            print("Error encoding data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil,
                  let data = data else {
                print("Error: \(error!)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                  print("Server error")
                  print(String(data: data, encoding: .utf8) ?? "" )
                return
              }
            
            print("Save success.")
        }.resume()
    }
    
    // MARK: USER ID
    static var userID: String? = nil
    
    static func saveUserID(id: String) {
        userDefaults.setValue(id, forKey: userIDKey)
    }
    
    // MARK: ACCOUNT
    
    static func getSavedAccount() -> Account? {
        guard let storedData = userDefaults.object(forKey: savedAccountKey) as? Data,
              let decodedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: Account.self, from: storedData) else {
            return nil
        }
        
        return decodedObject
    }
    
    static func saveAccount(_ account: Account) {
        guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: true) else {
            return
        }
        
        userDefaults.set(encodedData, forKey: savedAccountKey)
    }
    
    static func removeSavedAccount() {
        userDefaults.removeObject(forKey: savedAccountKey)
    }
    
    // MARK: USER DATA
    static var userData: UserData = getOfflineUserData()
    
    static func getOfflineUserData() -> UserData {
        if let storedData = userDefaults.object(forKey: userDataKey) as? Data,
           let decodedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UserData.self, from: storedData) {
            return decodedObject
        } else {
            return UserData()
        }
    }
    static func getUserData(_ completion: @escaping (UserData?) -> Void) {
        
        if let id = userID {
            let link = serviceURL + "get_personal_info.php"
            
            let url = URL(string: link)
            guard let url = url else {
                completion(nil)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let payload = [
                    "user_ID": id
                ]
                let jsonData = try JSONEncoder().encode(payload)
                request.httpBody = jsonData
            } catch {
                fatalError("Error endoding userID")
            }
            
            var res: UserData? = nil
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data,
                      error == nil else {
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    return
                }
                
                let decoder = JSONDecoder()
                res = try? decoder.decode(UserData.self, from: data)
                completion(res)
            }.resume()
        } else {
            completion(nil)
        }
    }
    
    static func saveUserData(_ userData: UserData) {
        if let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: userData, requiringSecureCoding: true) {
            userDefaults.set(encodedData, forKey: userDataKey)
        }
        
        let id = userID
        
        if id != nil {
            let link = serviceURL + "update_personal_info.php"
            let url = URL(string: link)
            
            guard let url = url else {
                print("Cannot connect to web service.")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let jsonData = try JSONEncoder().encode(userData)
                request.httpBody = jsonData
            } catch {
                print("Error encoding Data: \(error)")
                return
            }
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard error == nil else {
                    print("Error: \(error!)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Server error.")
                    return
                }
                
                print("Successfully update health detail.")
            }.resume()
        } else {
            let link = serviceURL + "new_personal_info.php"
            let url = URL(string: link)
            
            guard let url = url else {
                print("Cannot connect to web service.")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let jsonData = try JSONEncoder().encode(userData)
                request.httpBody = jsonData
            } catch {
                print("Error encoding Data: \(error)")
                return
            }
            
            URLSession.shared.dataTask(with: request) {(data, response, error) in
                guard let data = data,
                      error == nil else {
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Server error.")
                    return
                }
                
                let result = String(data: data, encoding: .utf8) ?? ""
                if let _ = UUID(uuidString: result) {
                    saveUserID(id: result)
                }
            }.resume()
        }
        
        
        
    }
    
    // MARK: Profile picture
    static func getImageFromPath(path: String?, completion: @escaping (UIImage?) -> Void) {
        let defaultImage = UIImage(systemName: "person.circle.fill")
        if let path = path,
           !path.isEmpty {
            let urlString = serviceURL + path
            let url = URL(string: urlString)
            
            guard let url = url else {
                print("Cannot connect to website.")
                completion(defaultImage)
                return
            }
            
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                
                guard let data = data,
                      error == nil else {
                    print("Error connecting to server \(error!)")
                    completion(defaultImage)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Invalid Response.")
                    completion(defaultImage)
                    return
                }
                
                let image = UIImage(data: data)
                completion(image)
            }.resume()
            
        } else {
            if let savedImageData = UserDefaults.standard.data(forKey: "savedImageKey") {
                completion(UIImage(data: savedImageData))
                return
            } else {
                completion(defaultImage)
                return
            }
        }
        
    }
    
    static func saveProfileImage(_ image: UIImage) {
        if let imageData = image.pngData() {
            UserDefaults.standard.set(imageData, forKey: "savedImageKey")
            UserDefaults.standard.synchronize()
        }
        
        if let _ = userData.imgPath {
            let link = serviceURL + "update_pfpimage.php"
            let url = URL(string: link)
            
            guard let url = url else {
                print("Cannot connect to web service.")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let base64String = image.jpegData(compressionQuality: 0.5)?.base64EncodedString()
                let payload = [
                    "user_ID" : userData.userID,
                    "pfp_image" : base64String
                ]
                let jsonData = try JSONEncoder().encode(payload)
                request.httpBody = jsonData
            } catch {
                print("Error encoding Data: \(error)")
                return
            }
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard error == nil else {
                    print("Error: \(error!)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Server error")
                    return
                }
                print("Save Image success")
            }.resume()
        } else {
            saveNewImage(image)
        }
    }
    
    static func saveNewImage(_ image: UIImage) {
        if let imageData = image.pngData() {
            UserDefaults.standard.set(imageData, forKey: "savedImageKey")
            UserDefaults.standard.synchronize()
        }
        
        let link = serviceURL + "new_pfpimage.php"
        let url = URL(string: link)
        guard let url = url else {
            print("Cannot connect to web service.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let base64String = image.jpegData(compressionQuality: 1)?.base64EncodedString()
            let payload = [
                "user_ID" : userData.userID,
                "pfp_image" : base64String
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
        } catch {
            print("Error encoding data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil,
                  let data = data else {
                print("Error: \(error!)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let result = String(data: data, encoding: .utf8) ?? ""
                print("Server error: \(result)")
                return
            }
            print("Save Image success")
        }.resume()
    }
    
    // MARK: All data category definition
    static var HealthCategories: [HealthCategory] {
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
                    HKQuantityTypeIdentifier.walkingHeartRateAverage.rawValue,
                    HKCategoryTypeIdentifier.highHeartRateEvent.rawValue,
                    HKCategoryTypeIdentifier.irregularHeartRhythmEvent.rawValue,
                    HKCategoryTypeIdentifier.lowHeartRateEvent.rawValue
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
                    HKCategoryTypeIdentifier.toothbrushingEvent.rawValue,
                    HKCategoryTypeIdentifier.handwashingEvent.rawValue,
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
        
        var symtoms: HealthCategory {
            var symntomsType: [HKSampleType] {
                let identifier: [String] = [
                    HKCategoryTypeIdentifier.abdominalCramps.rawValue,
                    HKCategoryTypeIdentifier.acne.rawValue,
                    HKCategoryTypeIdentifier.appetiteChanges.rawValue,
                    HKCategoryTypeIdentifier.bladderIncontinence.rawValue,
                    HKCategoryTypeIdentifier.bloating.rawValue,
                    HKCategoryTypeIdentifier.breastPain.rawValue,
                    HKCategoryTypeIdentifier.chestTightnessOrPain.rawValue,
                    HKCategoryTypeIdentifier.chills.rawValue,
                    HKCategoryTypeIdentifier.constipation.rawValue,
                    HKCategoryTypeIdentifier.coughing.rawValue,
                    HKCategoryTypeIdentifier.diarrhea.rawValue,
                    HKCategoryTypeIdentifier.dizziness.rawValue,
                    HKCategoryTypeIdentifier.drySkin.rawValue,
                    HKCategoryTypeIdentifier.fainting.rawValue,
                    HKCategoryTypeIdentifier.fatigue.rawValue,
                    HKCategoryTypeIdentifier.fever.rawValue,
                    HKCategoryTypeIdentifier.generalizedBodyAche.rawValue,
                    HKCategoryTypeIdentifier.hairLoss.rawValue,
                    HKCategoryTypeIdentifier.headache.rawValue,
                    HKCategoryTypeIdentifier.heartburn.rawValue,
                    HKCategoryTypeIdentifier.hotFlashes.rawValue,
                    HKCategoryTypeIdentifier.lossOfSmell.rawValue,
                    HKCategoryTypeIdentifier.lossOfTaste.rawValue,
                    HKCategoryTypeIdentifier.lowerBackPain.rawValue,
                    HKCategoryTypeIdentifier.memoryLapse.rawValue,
                    HKCategoryTypeIdentifier.moodChanges.rawValue,
                    HKCategoryTypeIdentifier.nausea.rawValue,
                    HKCategoryTypeIdentifier.nightSweats.rawValue,
                    HKCategoryTypeIdentifier.pelvicPain.rawValue,
                    HKCategoryTypeIdentifier.rapidPoundingOrFlutteringHeartbeat.rawValue,
                    HKCategoryTypeIdentifier.runnyNose.rawValue,
                    HKCategoryTypeIdentifier.shortnessOfBreath.rawValue,
                    HKCategoryTypeIdentifier.sinusCongestion.rawValue,
                    HKCategoryTypeIdentifier.skippedHeartbeat.rawValue,
                    HKCategoryTypeIdentifier.sleepChanges.rawValue,
                    HKCategoryTypeIdentifier.soreThroat.rawValue,
                    HKCategoryTypeIdentifier.vaginalDryness.rawValue,
                    HKCategoryTypeIdentifier.vomiting.rawValue,
                    HKCategoryTypeIdentifier.wheezing.rawValue
                ]
                
                return identifier.compactMap {getSampleType(for: $0)}
            }
            return HealthCategory(categoryName: "Symtoms", dataTypes: symntomsType, icon: "list.bullet.clipboard", color: .purple)
        }
        
        var sleep: HealthCategory {
            var sleepType: [HKSampleType] {
                let identifier: [String] = [
                    HKCategoryTypeIdentifier.sleepAnalysis.rawValue
                ]
                
                return identifier.compactMap({getSampleType(for: $0)})
            }
            return HealthCategory(categoryName: "Sleep", dataTypes: sleepType, icon: "bed.double.fill", color: .cyan)
        }
        
        var menstruationCycle: HealthCategory {
            var cycleType:[HKSampleType] {
                let identifier: [String] = [
                    HKCategoryTypeIdentifier.cervicalMucusQuality.rawValue,
                    HKCategoryTypeIdentifier.contraceptive.rawValue,
                    HKCategoryTypeIdentifier.infrequentMenstrualCycles.rawValue,
                    HKCategoryTypeIdentifier.intermenstrualBleeding.rawValue,
                    HKCategoryTypeIdentifier.irregularMenstrualCycles.rawValue,
                    HKCategoryTypeIdentifier.lactation.rawValue,
                    HKCategoryTypeIdentifier.menstrualFlow.rawValue,
                    HKCategoryTypeIdentifier.ovulationTestResult.rawValue,
                    HKCategoryTypeIdentifier.persistentIntermenstrualBleeding.rawValue,
                    HKCategoryTypeIdentifier.pregnancy.rawValue,
                    HKCategoryTypeIdentifier.pregnancyTestResult.rawValue,
                    HKCategoryTypeIdentifier.progesteroneTestResult.rawValue,
                    HKCategoryTypeIdentifier.sexualActivity.rawValue,
                    HKCategoryTypeIdentifier.abdominalCramps.rawValue,
                    HKCategoryTypeIdentifier.acne.rawValue,
                    HKCategoryTypeIdentifier.bladderIncontinence.rawValue,
                    HKCategoryTypeIdentifier.bloating.rawValue,
                    HKCategoryTypeIdentifier.breastPain.rawValue,
                    HKCategoryTypeIdentifier.chills.rawValue,
                    HKCategoryTypeIdentifier.constipation.rawValue,
                    HKCategoryTypeIdentifier.diarrhea.rawValue,
                    HKCategoryTypeIdentifier.drySkin.rawValue,
                    HKCategoryTypeIdentifier.fatigue.rawValue,
                    HKCategoryTypeIdentifier.hairLoss.rawValue,
                    HKCategoryTypeIdentifier.headache.rawValue,
                    HKCategoryTypeIdentifier.hotFlashes.rawValue,
                    HKCategoryTypeIdentifier.lowerBackPain.rawValue,
                    HKCategoryTypeIdentifier.memoryLapse.rawValue,
                    HKCategoryTypeIdentifier.moodChanges.rawValue,
                    HKCategoryTypeIdentifier.nausea.rawValue,
                    HKCategoryTypeIdentifier.nightSweats.rawValue,
                    HKCategoryTypeIdentifier.pelvicPain.rawValue,
                    HKCategoryTypeIdentifier.sleepChanges.rawValue,
                    HKCategoryTypeIdentifier.vaginalDryness.rawValue,
                    HKQuantityTypeIdentifier.appleSleepingWristTemperature.rawValue
                ]
                
                return identifier.compactMap({getSampleType(for: $0)})
            }
            return HealthCategory(categoryName: "Cycle Tracking", dataTypes: cycleType, icon: "arrow.triangle.2.circlepath", color: .systemPink)
        }
        
        return [activity, bodyMeasurement, hearingHealth, heart, nutrition, mobility, respiratory, vitalSign, sleep, symtoms, menstruationCycle, other]
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
            HKQuantityTypeIdentifier.walkingAsymmetryPercentage.rawValue,
            HKCategoryTypeIdentifier.irregularHeartRhythmEvent.rawValue,
            HKCategoryTypeIdentifier.lowHeartRateEvent.rawValue,
            HKCategoryTypeIdentifier.highHeartRateEvent.rawValue,
            HKCategoryTypeIdentifier.irregularMenstrualCycles.rawValue,
            HKCategoryTypeIdentifier.infrequentMenstrualCycles.rawValue,
            HKCategoryTypeIdentifier.persistentIntermenstrualBleeding.rawValue,
            HKCategoryTypeIdentifier.environmentalAudioExposureEvent.rawValue,
            HKCategoryTypeIdentifier.headphoneAudioExposureEvent.rawValue,
            HKCategoryTypeIdentifier.appleWalkingSteadinessEvent.rawValue,
            HKCategoryTypeIdentifier.lowCardioFitnessEvent.rawValue,
        ]
    }
    
    static var categoryValueType: [String] {
        return [
            HKCategoryTypeIdentifier.mindfulSession.rawValue,
            HKCategoryTypeIdentifier.handwashingEvent.rawValue,
            HKCategoryTypeIdentifier.toothbrushingEvent.rawValue,
            HKCategoryTypeIdentifier.infrequentMenstrualCycles.rawValue,
            HKCategoryTypeIdentifier.intermenstrualBleeding.rawValue,
            HKCategoryTypeIdentifier.irregularMenstrualCycles.rawValue,
            HKCategoryTypeIdentifier.lactation.rawValue,
            HKCategoryTypeIdentifier.persistentIntermenstrualBleeding.rawValue,
            HKCategoryTypeIdentifier.pregnancy.rawValue,
            HKCategoryTypeIdentifier.sexualActivity.rawValue
        ]
    }
    
    static var notificationType: [String] {
        return [
            HKCategoryTypeIdentifier.highHeartRateEvent.rawValue,
            HKCategoryTypeIdentifier.irregularHeartRhythmEvent.rawValue,
            HKCategoryTypeIdentifier.lowHeartRateEvent.rawValue,
            HKCategoryTypeIdentifier.lowCardioFitnessEvent.rawValue,
            HKCategoryTypeIdentifier.environmentalAudioExposureEvent.rawValue,
            HKCategoryTypeIdentifier.headphoneAudioExposureEvent.rawValue,
            HKCategoryTypeIdentifier.appleWalkingSteadinessEvent.rawValue
        ]
    }
    
    static var scatterChartType: [String] {
        return [
            HKCategoryTypeIdentifier.cervicalMucusQuality.rawValue,
            HKCategoryTypeIdentifier.contraceptive.rawValue,
            HKCategoryTypeIdentifier.menstrualFlow.rawValue,
            HKCategoryTypeIdentifier.ovulationTestResult.rawValue,
            HKCategoryTypeIdentifier.pregnancyTestResult.rawValue,
            HKCategoryTypeIdentifier.progesteroneTestResult.rawValue
        ]
    }
    
    static var interestAreas: [InterestArea] {
        var diabetes: InterestArea {
            let dataTypes = [HKQuantityTypeIdentifier.bloodGlucose.rawValue,
                             HKQuantityTypeIdentifier.insulinDelivery.rawValue,
                             HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
                             HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue]
            
            return InterestArea(name: "Diabetes", dataTypes: dataTypes)
        }
        
        var heartHealth: InterestArea {
            let dataTypes = [HKQuantityTypeIdentifier.heartRate.rawValue,
                             HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
                             HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue,
                             HKQuantityTypeIdentifier.heartRateRecoveryOneMinute.rawValue,
                             HKQuantityTypeIdentifier.restingHeartRate.rawValue,
                             HKQuantityTypeIdentifier.peripheralPerfusionIndex.rawValue,
                             HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue,
                             HKQuantityTypeIdentifier.atrialFibrillationBurden.rawValue,
                             HKQuantityTypeIdentifier.bodyMassIndex.rawValue,
                             HKQuantityTypeIdentifier.forcedExpiratoryVolume1.rawValue,
                             HKCategoryTypeIdentifier.chestTightnessOrPain.rawValue,
                             HKCategoryTypeIdentifier.rapidPoundingOrFlutteringHeartbeat.rawValue,
                             HKCategoryTypeIdentifier.skippedHeartbeat.rawValue
            ]
            
            return InterestArea(name: "Heart Health", dataTypes: dataTypes)
        }
        
        var allergies_asthma: InterestArea {
            let dataTypes = [HKQuantityTypeIdentifier.respiratoryRate.rawValue,
                             HKQuantityTypeIdentifier.inhalerUsage.rawValue,
                             HKQuantityTypeIdentifier.forcedVitalCapacity.rawValue,
                             HKQuantityTypeIdentifier.oxygenSaturation.rawValue,
                             HKQuantityTypeIdentifier.forcedExpiratoryVolume1.rawValue,
                             HKQuantityTypeIdentifier.peakExpiratoryFlowRate.rawValue,
                             HKCategoryTypeIdentifier.chestTightnessOrPain.rawValue,
                             HKCategoryTypeIdentifier.coughing.rawValue,
                             HKCategoryTypeIdentifier.shortnessOfBreath.rawValue,
                             HKCategoryTypeIdentifier.runnyNose.rawValue,
                             HKCategoryTypeIdentifier.sinusCongestion.rawValue,
                             HKCategoryTypeIdentifier.wheezing.rawValue
            ]
            
            return InterestArea(name: "Allergies/ Asthma", dataTypes: dataTypes)
        }
        
        var exercise_fitness: InterestArea {
            let dataTypes = [HKQuantityTypeIdentifier.stepCount.rawValue,
                             HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
                             HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
                             HKQuantityTypeIdentifier.appleExerciseTime.rawValue,
                             HKQuantityTypeIdentifier.appleMoveTime.rawValue,
                             HKQuantityTypeIdentifier.appleStandTime.rawValue,
                             HKQuantityTypeIdentifier.appleWalkingSteadiness.rawValue,
                             HKQuantityTypeIdentifier.walkingSpeed.rawValue,
                             HKQuantityTypeIdentifier.walkingStepLength.rawValue,
                             HKQuantityTypeIdentifier.walkingDoubleSupportPercentage.rawValue,
                             HKQuantityTypeIdentifier.stairAscentSpeed.rawValue,
                             HKQuantityTypeIdentifier.stairDescentSpeed.rawValue,
                             HKQuantityTypeIdentifier.runningVerticalOscillation.rawValue,
                             HKQuantityTypeIdentifier.sixMinuteWalkTestDistance.rawValue
            ]
            
            return InterestArea(name: "Exercise/ Fitness", dataTypes: dataTypes)
        }
        
        var weightLoss: InterestArea {
            let dataTypes = [HKQuantityTypeIdentifier.bodyMass.rawValue,
                             HKQuantityTypeIdentifier.bodyMassIndex.rawValue,
                             HKQuantityTypeIdentifier.leanBodyMass.rawValue,
                             HKQuantityTypeIdentifier.waistCircumference.rawValue,
                             HKQuantityTypeIdentifier.bodyFatPercentage.rawValue,
                             HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
                             HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
                             HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue,
                             HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue,
                             HKQuantityTypeIdentifier.dietaryFatTotal.rawValue,
                             HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue,
                             HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue,
                             HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue,
                             HKQuantityTypeIdentifier.dietaryWater.rawValue,
                             HKQuantityTypeIdentifier.dietaryCholesterol.rawValue,
                             HKQuantityTypeIdentifier.dietaryProtein.rawValue
            ]
            
            return InterestArea(name: "Weight Loss", dataTypes: dataTypes)
        }
        
        var cycling: InterestArea {
            let dataTypes = [HKQuantityTypeIdentifier.distanceCycling.rawValue,
                             HKQuantityTypeIdentifier.cyclingCadence.rawValue,
                             HKQuantityTypeIdentifier.cyclingFunctionalThresholdPower.rawValue,
                             HKQuantityTypeIdentifier.cyclingPower.rawValue,
                             HKQuantityTypeIdentifier.cyclingSpeed.rawValue
            ]
            
            return InterestArea(name: "Cycling", dataTypes: dataTypes)
        }
        
        var swimming: InterestArea {
            let dataTypes = [HKQuantityTypeIdentifier.distanceSwimming.rawValue,
                             HKQuantityTypeIdentifier.underwaterDepth.rawValue,
                             HKQuantityTypeIdentifier.swimmingStrokeCount.rawValue]
            
            return InterestArea(name: "Swimming", dataTypes: dataTypes)
        }
        
        var snowboarding: InterestArea {
            let dataTypes = [HKQuantityTypeIdentifier.distanceDownhillSnowSports.rawValue]
            
            return InterestArea(name: "Snowboarding", dataTypes: dataTypes)
        }
        
        var running: InterestArea {
            let dataTypes = [HKQuantityTypeIdentifier.runningPower.rawValue,
                             HKQuantityTypeIdentifier.runningSpeed.rawValue,
                             HKQuantityTypeIdentifier.runningStrideLength.rawValue,
                             HKQuantityTypeIdentifier.runningGroundContactTime.rawValue]
            
            return InterestArea(name: "Running", dataTypes: dataTypes)
        }
        
        var hearingHealth: InterestArea {
            let dataTypes = [HKQuantityTypeIdentifier.headphoneAudioExposure.rawValue,
                             HKQuantityTypeIdentifier.environmentalAudioExposure.rawValue,
                             HKQuantityTypeIdentifier.environmentalSoundReduction.rawValue]
            
            return InterestArea(name: "Hearing Health", dataTypes: dataTypes)
        }
        
        var sleep: InterestArea {
            let dataTypes = [HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
                             HKQuantityTypeIdentifier.appleSleepingWristTemperature.rawValue,
                             HKCategoryTypeIdentifier.sleepChanges.rawValue,
                             HKCategoryTypeIdentifier.nightSweats.rawValue]
            
            return InterestArea(name: "Sleep", dataTypes: dataTypes)
        }
        
        return [diabetes, heartHealth, allergies_asthma, exercise_fitness, weightLoss, cycling, swimming, snowboarding, running, hearingHealth, sleep]
    }
}


/*
 HKCategoryTypeIdentifierIrregularMenstrualCycles,
 HKCategoryTypeIdentifierInfrequentMenstrualCycles,
 HKCategoryTypeIdentifierPersistentIntermenstrualBleeding"
 */

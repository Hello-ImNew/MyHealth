//
//  UserData.swift
//  MyHealth
//
//  Created by Bao Bui on 12/8/23.
//

import Foundation
import UIKit

class UserData: NSObject, NSSecureCoding, Codable {
    static var supportsSecureCoding: Bool = true
    
    var userID: String?
    var firstName: String?
    var lastName: String?
    var birthDate: Date?
    var bioSex: sex?
    var bloodType: blood?
    var fitzpatrickSkinType: skin?
    var imgPath: String?
    var isInterestSelected: Bool
        
    enum sex: String {
        case male = "Male"
        case female = "Female"
        case other = "Other"
    }
    
    enum blood: String {
        case APlus = "A+"
        case AMinus = "A-"
        case BPlus = "B+"
        case BMinus = "B-"
        case ABPlus = "AB+"
        case ABMinus = "AB-"
        case OPlus = "O+"
        case OMinus = "O-"
    }
    
    enum skin: String {
        case type1 = "Type I"
        case type2 = "Type II"
        case type3 = "Type III"
        case type4 = "Type IV"
        case type5 = "Type V"
        case type6 = "Type VI"
    }
    
    enum CodingKeys: String, CodingKey {
        case token = "token"
        case userID = "user_ID"
        case firstName = "first_name"
        case lastName = "last_name"
        case birthDate = "birth_date"
        case bioSex = "bio_sex"
        case bloodType = "blood_type"
        case fitzpatrickSkinType = "skin_type"
        case imgPath = "image_path"
        case isInterestSelected = "is_interest_selected"
    }
    
    init(id: String? = nil) {
        self.userID = id
        self.firstName = nil
        self.lastName = nil
        self.birthDate = nil
        self.bioSex = nil
        self.bloodType = nil
        self.fitzpatrickSkinType = nil
        self.imgPath = nil
        self.isInterestSelected = false
    }
    
    required init?(coder: NSCoder) {
        self.userID = coder.decodeObject(of: NSString.self, forKey: "user_ID") as? String
        self.firstName = coder.decodeObject(of: NSString.self, forKey: "first_name") as? String
        self.lastName = coder.decodeObject(of: NSString.self, forKey: "last_name") as? String
        self.birthDate = coder.decodeObject(of: NSDate.self, forKey: "birth_date") as? Date
        self.bioSex = sex(rawValue: (coder.decodeObject(of: NSString.self, forKey: "bio_sex") as? String) ?? "")
        self.bloodType = blood(rawValue: (coder.decodeObject(of: NSString.self, forKey: "blood_type") as? String) ?? "")
        self.fitzpatrickSkinType = skin(rawValue: (coder.decodeObject(of: NSString.self, forKey: "skin_type") as? String) ?? "")
        self.isInterestSelected = coder.decodeObject(forKey: "is_interest_selected") as? Bool ?? false
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(firstName, forKey: "first_name")
        coder.encode(lastName, forKey: "last_name")
        coder.encode(birthDate, forKey: "birth_date")
        coder.encode(bioSex?.rawValue, forKey: "bio_sex")
        coder.encode(bloodType?.rawValue, forKey: "blood_type")
        coder.encode(fitzpatrickSkinType?.rawValue, forKey: "skin_type")
        coder.encode(isInterestSelected as Any, forKey: "is_interest_selected")
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userID = try? container.decode(String.self, forKey: .userID)
        self.firstName = try? container.decode(String.self, forKey: .firstName)
        self.lastName = try? container.decode(String.self, forKey: .lastName)
        self.bioSex = sex(rawValue: (try? container.decode(String.self, forKey: .bioSex)) ?? "")
        self.bloodType = blood(rawValue: (try? container.decode(String.self, forKey: .bloodType)) ?? "")
        self.fitzpatrickSkinType = skin(rawValue: (try? container.decode(String.self, forKey: .fitzpatrickSkinType)) ?? "")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        self.birthDate = formatter.date(from: (try? container.decode(String.self, forKey: .birthDate)) ?? "")
        self.imgPath = try? container.decode(String.self, forKey: .imgPath)
        let isInterestSelected = (try? container.decode(Int.self, forKey: .isInterestSelected)) ?? 0
        self.isInterestSelected = isInterestSelected != 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(webserviceToken, forKey: .token)
        try container.encode(self.userID, forKey: .userID)
        try container.encode(self.firstName, forKey: .firstName)
        try container.encode(self.lastName, forKey: .lastName)
        try container.encode(self.bioSex?.rawValue, forKey: .bioSex)
        try container.encode(self.bloodType?.rawValue, forKey: .bloodType)
        try container.encode(self.fitzpatrickSkinType?.rawValue, forKey: .fitzpatrickSkinType)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let bDateString: String?
        if let birthDate = self.birthDate {
            bDateString = formatter.string(from: birthDate)
        } else {
            bDateString = nil
        }
        
        try container.encode(bDateString, forKey: .birthDate)
        try container.encode(self.imgPath, forKey: .imgPath)
        try container.encode(self.isInterestSelected ? 1 : 0, forKey: .isInterestSelected)
        
    }
    
    static func getSex(rawValue value: Int) -> sex? {
        let dict: [Int: sex] = [
            1: .female,
            2: .male,
            3: .other
        ]
        
        return dict[value]
    }
    
    static func getBloodType(rawValue type: Int) -> blood? {
        let dict: [Int: blood] = [
            1: .APlus,
            2: .AMinus,
            3: .BPlus,
            4: .BMinus,
            5: .ABPlus,
            6: .ABMinus,
            7: .OPlus,
            8: .OMinus
        ]
        
        return dict[type]
    }
    
    static func getSkinType(rawValue type: Int) -> skin? {
        let dict: [Int: skin] = [
            1: .type1,
            2: .type2,
            3: .type3,
            4: .type4,
            5: .type5,
            6: .type6,
        ]
        
        return dict[type]
    }
    
    func getUserData() -> UserData {
        let userDefaults = UserDefaults.standard
        let userIDKey = "user_ID"
        var result: UserData = UserData()
        let group = DispatchGroup()
        
        if let id = userDefaults.string(forKey: userIDKey) {
            let path = newServiceURL + "personal_info/get_personal_info.php"
            let url = URL(string: path)
            
            guard let url = url else {
                return result
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let payload: [String: Any] = [
                    "user_ID": id
                ]
                let jsonData = try JSONSerialization.data(withJSONObject: payload)
                request.httpBody = jsonData
            } catch {
                print("Error encoding data: \(error)")
            }
            
            group.enter()
            
            ViewModels.sharedSession.dataTask(with: request) { (data, response, error) in
                guard let data = data, error == nil else {
                    print("Error connect to server \(error!)")
                    result = ViewModels.userData
                    group.leave()
                    return
                }
                
                let decoder = JSONDecoder()
                if let userData = try? decoder.decode(UserData.self, from: data) {
                    result = userData
                }
                group.leave()
            }.resume()
        }
        group.wait()
        return result
    }
    
    private func isValidUUID(_ string: String) -> Bool {
        if let _ = UUID(uuidString: string) {
            return true
        } else {
            return false
        }
    }
}

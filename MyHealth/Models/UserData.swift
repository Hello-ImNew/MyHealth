//
//  UserData.swift
//  MyHealth
//
//  Created by Bao Bui on 12/8/23.
//

import Foundation

class UserData: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    
    var firstName: String?
    var lastName: String?
    var birthDate: Date?
    var bioSex: sex?
    var bloodType: blood?
    var fitzpatrickSkinType: skin?
        
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
    
    override init() {
        self.firstName = nil
        self.lastName = nil
        self.birthDate = nil
        self.bioSex = nil
        self.bloodType = nil
        self.fitzpatrickSkinType = nil
    }
    
    required init?(coder: NSCoder) {
        self.firstName = coder.decodeObject(of: NSString.self, forKey: "first_name") as? String
        self.lastName = coder.decodeObject(of: NSString.self, forKey: "last_name") as? String
        self.birthDate = coder.decodeObject(of: NSDate.self, forKey: "birth_date") as? Date
        self.bioSex = sex(rawValue: (coder.decodeObject(of: NSString.self, forKey: "bio_sex") as? String) ?? "")
        self.bloodType = blood(rawValue: (coder.decodeObject(of: NSString.self, forKey: "blood_type") as? String) ?? "")
        self.fitzpatrickSkinType = skin(rawValue: (coder.decodeObject(of: NSString.self, forKey: "skin_type") as? String) ?? "")
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(firstName, forKey: "first_name")
        coder.encode(lastName, forKey: "last_name")
        coder.encode(birthDate, forKey: "birth_date")
        coder.encode(bioSex?.rawValue, forKey: "bio_sex")
        coder.encode(bloodType?.rawValue, forKey: "blood_type")
        coder.encode(fitzpatrickSkinType?.rawValue, forKey: "skin_type")
        
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
}

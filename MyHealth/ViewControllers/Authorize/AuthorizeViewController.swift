//
//  AuthorizeViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 11/9/23.
//

import UIKit
import HealthKit

class AuthorizeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print(HKCategoryTypeIdentifier.RawValue.self)
    }
    
    @IBAction func clickedAuthorize(_ sender: Any) {
        var share: [HKSampleType] = []
        var read: [HKSampleType] = []
        for category in ViewModels.HealthCategories {
            for type in category.dataTypes {
                read.append(type)
                if isAllowedShared(for: type.identifier) {
                    share.append(type)
                }
            }
        }
        
        HealthData.requestHealthDataAccessIfNeeded(toShare: Set(share), read: Set(read)) {success in 
            if !success {
                print("Error in requesting Authorization ")
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

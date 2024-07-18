//
//  AddCategoryValueViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 2/23/24.
//

import UIKit
import HealthKit

class AddCategoryValueViewController: UIViewController {
    
    @IBOutlet weak var startDpk: UIDatePicker!
    @IBOutlet weak var tfdSecNum: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var identifier: String = ""
    var secNum: Int?
    weak var delegate: AddDataDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        let categoryIdentifier = HKCategoryTypeIdentifier(rawValue: identifier)
        guard let type = HKObjectType.categoryType(forIdentifier: categoryIdentifier) else {
            showAlert(title: "Identifier Fault", message: "Cannot get Category Type from identifier")
            return
        }
        guard let secnum = self.secNum else {
            showAlert(title: "Duration Not Neconized", message: "Please enter duration time")
            return
        }
        
        let start = startDpk.date
        let end = start + TimeInterval(secnum)
        
        let sample = HKCategorySample(type: type, value: 0, start: start, end: end)
        
        HealthData.healthStore.save(sample, withCompletion: {(success, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error in Saving data", message: "\(error.localizedDescription)")
                }
            }
            if success {
                print("Save Data Success")
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.delegate?.showData()
                    }
                }
            }
        })
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func secNumChange(_ sender: Any) {
        if let secNumTxt = tfdSecNum.text,
           !secNumTxt.isEmpty,
           let secnum = Int(secNumTxt) {
            saveButton.isEnabled = true
            self.secNum = secnum
        } else {
            saveButton.isEnabled = false
            self.secNum = nil
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

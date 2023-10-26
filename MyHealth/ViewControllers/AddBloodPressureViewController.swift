//
//  AddBloodPressureViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 10/23/23.
//

import UIKit
import HealthKit

class AddBloodPressureViewController: UIViewController {
    
    @IBOutlet weak var dtpDate: UIDatePicker!
    @IBOutlet weak var dtpTime: UIDatePicker!
    @IBOutlet weak var txtSystolic: UITextField!
    @IBOutlet weak var txtDiastolic: UITextField!
    
    var delegate: AddDataDelegate?
    var isSystolicReady: Bool = false
    var isDiastolicReady: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func clickedCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func clickedSave(_ sender: Any) {
        let date = dtpDate.date
        let time = dtpTime.date
        let calendar = Calendar.current
        
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        let combinedDate = calendar.date(bySettingHour: timeComponents.hour!, minute: timeComponents.minute!, second: timeComponents.second!, of: date)!
        
        let identifier1 = HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue
        let identifier2 = HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue
        
        guard let sample1 = processHealthSample(for: identifier1, value: Double(txtSystolic.text!)!, date: combinedDate),
              let sample2 = processHealthSample(for: identifier2, value: Double(txtDiastolic.text!)!, date: combinedDate)
        else {return}
        
        HealthData.saveHealthData([sample1, sample2]) { (success, error) in
            if let error = error {
                print("Error in Saving Data:", error.localizedDescription)
            }
            if success {
                print("Successfully saved a new sample!", sample1, sample2)
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.delegate?.showData()
                    }
                }
            } else {
                print("Error: Could not save new sample.", sample1, sample2)
            }
        }
    }
    
    @IBAction func systolicChanged(_ sender: Any) {
        if Double(txtSystolic.text ?? "") != nil {
            isSystolicReady = true
        } else {
            isSystolicReady = false
        }
        checkAddEnable()
    }
    
    @IBAction func diastolicChanged(_ sender: Any) {
        if Double(txtDiastolic.text ?? "") != nil {
            isDiastolicReady = true
        } else {
            isDiastolicReady = false
        }
        checkAddEnable()
    }
    
    func checkAddEnable() {
        self.navigationItem.rightBarButtonItem?.isEnabled = isSystolicReady && isDiastolicReady
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

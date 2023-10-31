//
//  AddHealthDataViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 10/23/23.
//

import UIKit

protocol AddDataDelegate: AnyObject {
    func showData()
}

class AddHealthDataViewController: UIViewController {
    
    var dataTypeIDentifier: String = ""
    var delegate: AddDataDelegate?
    @IBOutlet weak var lblUnit: UILabel!
    @IBOutlet weak var dtpDate: UIDatePicker!
    @IBOutlet weak var dtpTime: UIDatePicker!
    @IBOutlet weak var txtValue: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        lblUnit.text = getUnit(for: dataTypeIDentifier)
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
            
        guard let sample = processHealthSample(for: dataTypeIDentifier, value: Double(txtValue.text!)!, date: combinedDate)
        else {return}
        
        HealthData.saveHealthData([sample]) { (success, error) in
            if let error = error {
                print("Error in Saving Data:", error.localizedDescription)
                let alertController = UIAlertController(title: "Saving Data Error", message: error.localizedDescription, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "OK", style: .cancel)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true)
            }
            if success {
                print("Successfully saved a new sample!", sample)
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.delegate?.showData()
                    }
                }
            } else {
                print("Error: Could not save new sample.", sample)
            }
        }
    }
    
    @IBAction func txtfldEdit(_ sender: Any) {
        if Double(txtValue.text ?? "") != nil {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
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

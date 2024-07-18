//
//  AddCategoryOneDpkViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 3/1/24.
//

import UIKit
import HealthKit

class AddCategoryOneDpkViewController: UIViewController {

    @IBOutlet weak var datePk: UIDatePicker!
    @IBOutlet weak var btnYesNo: UIButton!
    @IBOutlet weak var TableView: UITableView!
    @IBOutlet weak var metadataStackView: UIStackView!
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    
    weak var delegate: AddDataDelegate?
    var identifier: String = ""
    var selectedMetadata: metadata?
    var selectedValue: Int?
    let buttonOptions = ["No", "Yes"]
    var values: [String] {
        return getCategoryValues(for: identifier)
    }
    enum metadata: String {
        case yes = "Yes"
        case no = "No"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if identifier == HKCategoryTypeIdentifier.menstrualFlow.rawValue {
            metadataStackView.isHidden = false
            SetUpButton()
        } else {
            metadataStackView.isHidden = true
        }
    }
    
    func SetUpButton() {
        btnYesNo.layer.cornerRadius = 5
        btnYesNo.clipsToBounds = true
        let optionClosure = {(action: UIAction) in
            switch action.title {
            case self.buttonOptions[0]:
                self.selectedMetadata = .no
            case self.buttonOptions[1]:
                self.selectedMetadata = .yes
            default:
                return
            }
        }
        
        var options = buttonOptions.map({UIAction(title: $0, handler: optionClosure)})
        btnYesNo.changesSelectionAsPrimaryAction = true
        btnYesNo.showsMenuAsPrimaryAction = true
        btnYesNo.menu = UIMenu(children: options)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func saveData(_ sender: Any) {
        let categoryIdentifier = HKCategoryTypeIdentifier(rawValue: identifier)
        guard let type: HKCategoryType = HKObjectType.categoryType(forIdentifier: categoryIdentifier) else {
            showAlert(title: "Identifier Fault", message: "Cannot get Category Type from identifier")
            return
        }
        
        guard let value = selectedValue else {
            showAlert(title: "No Value Selected", message: "Please select a value")
            return
        }
        
        let date = datePk.date
        let metadata: [String: Any]?
        if identifier == HKCategoryTypeIdentifier.menstrualFlow.rawValue {
            metadata = [HKMetadataKeyMenstrualCycleStart: selectedMetadata == .yes]
        } else {
            metadata = nil
        }
        let sample = HKCategorySample(type: type, value: value + 1, start: date, end: date, metadata: metadata)
        let temp = sample.metadata
        
        HealthData.healthStore.save(sample) { (success, error) in
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

extension AddCategoryOneDpkViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count - 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryValueCell", for: indexPath)
        cell.textLabel?.text = values[indexPath.row + 1]
        if let value = selectedValue,
           value == indexPath.row {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let oldSelectedValue = selectedValue {
            let oldIndexPath = IndexPath(row: oldSelectedValue, section: indexPath.section)
            tableView.reloadRows(at: [oldIndexPath], with: .automatic)
        }
        
        saveBtn.isEnabled = true
        
        selectedValue = indexPath.row
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

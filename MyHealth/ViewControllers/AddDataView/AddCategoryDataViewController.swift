//
//  AddCategoryDataViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 12/5/23.
//

import UIKit
import HealthKit

class AddCategoryDataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var dpkStart: UIDatePicker!
    @IBOutlet weak var dpkEnd: UIDatePicker!
    @IBOutlet weak var optionsView: UITableView!
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    
    var delegate: AddDataDelegate?
    var identifier: String = ""
    var options: [String] {
        return getCategoryValues(for: identifier)
    }
    var selectedRow: Int?
    
    var isSaveEnable: Bool {
        get {
            return saveBtn.isEnabled
        }
        set(value) {
            saveBtn.isEnabled = value
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        optionsView.dataSource = self
        optionsView.delegate = self
        optionsView.reloadData()
    }
    
    // MARK: Functions
    
    func isInSaveTime(start: Date, end: Date)-> Bool {
        var result : Bool = true
        let numSeconds: Double = end.timeIntervalSince(start)
        
        let categoryIdentifier = HKCategoryTypeIdentifier(rawValue: self.identifier)
        switch categoryIdentifier {
        case .bladderIncontinence, .chestTightnessOrPain, .drySkin, .chills, .coughing, .fainting, .dizziness, .sinusCongestion, .fever, .hairLoss, .heartburn, .lossOfSmell, .lossOfTaste, .memoryLapse, .nightSweats:
            result = numSeconds < 345600.0
        default:
            result = numSeconds < 1209600.0
        }
        return result
    }
    
    func checkTimeInteval() -> Bool {
        return isInSaveTime(start: dpkStart.date, end: dpkEnd.date)
    }
    
    // MARK: Tableview Setting
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryOptionCell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        if let selectedRow = selectedRow,
           selectedRow == indexPath.row {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let oldSelectedRow = selectedRow
        selectedRow = indexPath.row
        
        if let oldSelectedRow = oldSelectedRow {
            let oldIndexPath = IndexPath(row: oldSelectedRow, section: indexPath.section)
            tableView.reloadRows(at: [oldIndexPath], with: .automatic)
        }
        isSaveEnable = checkTimeInteval()
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    // MARK: Action, Event Handlers
    
    @IBAction func cancelClicked(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func startChange(_ sender: UIDatePicker) {
        if sender.date > dpkEnd.date {
            dpkEnd.date = sender.date
        }
        
        isSaveEnable = checkTimeInteval()
    }
    
    @IBAction func endChange(_ sender: UIDatePicker) {
        if sender.date < dpkStart.date {
            dpkStart.date = sender.date
        }
        
        isSaveEnable = checkTimeInteval()
    }
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        let categoryIdentifier = HKCategoryTypeIdentifier(rawValue: identifier)
        guard let type: HKCategoryType = HKObjectType.categoryType(forIdentifier: categoryIdentifier) else {
            let alertController = showAlert(title: "Identifier Fault", message: "Cannot get Category Type from identifier")
            self.present(alertController, animated: true)
            return
        }
        
        guard let value = selectedRow else {
            let alertController = showAlert(title: "No Value Selected", message: "Please select a value")
            self.present(alertController, animated: true)
            return
        }
        
        let start = dpkStart.date
        let end = dpkEnd.date
        let sample = HKCategorySample(type: type, value: value, start: start, end: end)
        
        HealthData.healthStore.save(sample) { (success, error) in
            if let error = error {
                DispatchQueue.main.async {
                    let alertController = showAlert(title: "Error in Saving data", message: "\(error.localizedDescription)")
                    self.present(alertController, animated: true)
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

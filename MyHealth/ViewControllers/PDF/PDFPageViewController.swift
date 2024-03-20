//
//  PDFPageViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 1/22/24.
//

import UIKit
import HealthKit

struct PDFOption {
    let title: String
    let segue: String
}

class PDFPageViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dpkEnd: UIDatePicker!
    @IBOutlet weak var dpkStart: UIDatePicker!
    @IBOutlet weak var optSelectBtn: UIButton!
    
    var start: Date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date())!)
    var end: Date = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
    
//    let reportTypes: [PDFOption] = [
//        PDFOption(title: "Report Favorite Health Types", segue: "PDFPreviewSegue"),
//        PDFOption(title: "Report Selected Health Types", segue: "SelectDataTypeSegue"),
//        PDFOption(title: "Report Based on Category", segue: "SelectCategorySegue")
//    ]
    var selectedRow: Int?
    let actionTitle = ["Report Favorite Health Types",
                       "Report Selected Health Types",
                       "Report Based on Category"]
    
    var selectedTypes = Set<HKSampleType>()
    var selectedOption: PDFoption?
    
    var favType: [HKSampleType] {
        var res: [HKSampleType] = []
        for i in ViewModels.favDataType {
            if i is HKQuantityType {
                res.append(i)
            }
        }
        
        return res
    }
    
    let allCategories = ViewModels.HealthCategories
    var allData: [HKSampleType] {
        var visited = Set<String>()
        var res: [HKSampleType] = []
        
        for category in ViewModels.HealthCategories {
            for type in category.dataTypes {
                if !visited.contains(type.identifier),
                   type is HKQuantityType,
                   type.identifier != HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue {
                    visited.insert(type.identifier)
                    res.append(type)
                }
            }
        }
        
        return res
    }
    
    enum PDFoption {
        case fav
        case selectType
        case selectCategory
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        dpkStart.date = start
        dpkEnd.date = end
        dpkStart.maximumDate = dpkEnd.date
        dpkStart.minimumDate = Calendar.current.date(byAdding: .month, value: -1, to: end)
        
        setUpDropButton()
        
    }
    
    func setUpDropButton() {
        let optionClosure = {(action: UIAction) in
            switch action.title {
            case self.actionTitle[0]:
                self.selectedOption = .fav
            case self.actionTitle[1]:
                self.selectedOption = .selectType
            case self.actionTitle[2]:
                self.selectedOption = .selectCategory
            default:
                return
            }
            self.tableView.reloadData()
            if let _ = self.selectedOption {
                self.tableView.isUserInteractionEnabled = true
            } else {
                self.tableView.isUserInteractionEnabled = false
            }
        }
        var options = actionTitle.map({UIAction(title: $0, handler: optionClosure)})
        options.append(UIAction(title: "Select Report Option", attributes: [.hidden], state: .on, handler: {_ in }))
        optSelectBtn.changesSelectionAsPrimaryAction = true
        optSelectBtn.showsMenuAsPrimaryAction = true
        optSelectBtn.menu = UIMenu(title: "Report Options", children: options)
    }
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
    
    @IBAction func dpkEndChange(_ sender: UIDatePicker) {
        end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: sender.date)!
        dpkStart.maximumDate = end
        dpkStart.minimumDate = Calendar.current.date(byAdding: .month, value: -1, to: end)
    }
    
    @IBAction func dpkStartChange(_ sender: UIDatePicker) {
        start = Calendar.current.startOfDay(for: sender.date)
    }
    
    @IBAction func shareTapped(_ sender: Any) {
        if let selectedOption = selectedOption {
            switch selectedOption {
            case .fav:
                performSegue(withIdentifier: "PDFPreviewSegue", sender: self)
            case .selectType:
                if selectedTypes.isEmpty {
                    createAlert(title: "No Health Type Selected", message: "Please Select Health Type To Generate Report")
                } else {
                    performSegue(withIdentifier: "PDFPreviewSegue", sender: self)
                }
            case .selectCategory:
                if selectedRow != nil {
                    performSegue(withIdentifier: "PDFPreviewSegue", sender: self)
                } else {
                    createAlert(title: "No Health Category Selected", message: "Please Select Health Category To Generate Report")
                }
            }
        } else {
            createAlert(title: "No Option Selected", message: "Please Select Report Option")
        }
        
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "PDFPreviewSegue":
            let previewVC = segue.destination as? PDFPreviewViewController
            switch selectedOption {
            case .fav:
                previewVC?.dataList = Set<HKSampleType>(favType)
            case .selectType:
                previewVC?.dataList = selectedTypes
            case .selectCategory:
                previewVC?.categoryIndex = selectedRow!
            case nil:
                return
            }
            previewVC?.startDate = start
            previewVC?.endDate = end
        default:
            return
        }
    }
    

}

extension PDFPageViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let selectedOption = selectedOption {
            switch selectedOption {
            case .fav:
                return favType.count
            case .selectType:
                return allData.count
            case .selectCategory:
                return allCategories.count
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportOptionCell", for: indexPath)
        if let selectedOption = selectedOption {
            switch selectedOption {
            case .fav:
                let identifier = favType[indexPath.row].identifier
                cell.textLabel?.text = getDataTypeName(for: identifier)
                cell.imageView?.image = UIImage(systemName: getDataTypeIcon(for: identifier)!)
                cell.imageView?.tintColor = getDataTypeColor(for: identifier)
            case .selectType:
                let identifier = allData[indexPath.row].identifier
                cell.textLabel?.text = getDataTypeName(for: identifier)
                cell.imageView?.image = UIImage(systemName: getDataTypeIcon(for: identifier)!)
                cell.imageView?.tintColor = getDataTypeColor(for: identifier)
                
                if selectedTypes.contains(allData[indexPath.row]) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            case .selectCategory:
                let category = allCategories[indexPath.row]
                cell.textLabel?.text = category.categoryName
                cell.imageView?.image = UIImage(systemName: category.icon)
                cell.imageView?.tintColor = category.color
                
                if selectedRow == indexPath.row {
                    cell.accessoryType = .checkmark
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let selectedOption = selectedOption {
            switch selectedOption {
            case .selectType:
                let type = allData[indexPath.row]
                if selectedTypes.contains(type) {
                    selectedTypes.remove(type)
                } else {
                    selectedTypes.insert(type)
                }
                
                tableView.reloadRows(at: [indexPath], with: .automatic)
            case .selectCategory:
                if let lastRow = selectedRow {
                    let lastIndexPath = IndexPath(row: lastRow, section: 0)
                    let lastCell = tableView.cellForRow(at: lastIndexPath)
                    lastCell?.accessoryType = .none
                }
                
                let cell = tableView.cellForRow(at: indexPath)
                cell?.accessoryType = .checkmark
                selectedRow = indexPath.row
            case .fav:
                return
            }
        }
    }
}

extension PDFPageViewController: selectedTypeDelegate {
    func receivedTypes(_ types: Set<HKSampleType>) {
        selectedTypes = types
        performSegue(withIdentifier: "PDFPreviewSegue", sender: self)
    }
    
}

extension PDFPageViewController: selectCategoryDelegate {
    func receiveCategory(_ category: HealthCategory) {
        var types: [HKSampleType] {
            var res: [HKSampleType] = []
            for type in category.dataTypes {
                if type is HKQuantityType {
                    res.append(type)
                }
            }
            
            return res
        }
        
        selectedTypes = Set<HKSampleType>(types)
        performSegue(withIdentifier: "PDFPreviewSegue", sender: self)
    }
}

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
    @IBOutlet weak var optSelectBtn: UIButton!
    @IBOutlet weak var rangeBtn: UIButton!
    @IBOutlet weak var dateBtn: UIButton!
    @IBOutlet weak var datePicker: UIPickerView!
    @IBOutlet weak var rangeView: UIView!
    @IBOutlet weak var dateView: UIView!
    
    var selectedRange: rangeOption = .week
    var selectDay: Int = Calendar.current.component(.day, from: Date())
    var selectMonth: Int = Calendar.current.component(.month, from: Date())
    var selectYear: Int = Calendar.current.component(.year, from: Date())
    
    var yearOption: [Int] = Array(2015...(Calendar.current.component(.year, from: Date()) + 5))
    var monthOption: [Int] = Array(1...12)
    let rangeOptions: [rangeOption] = [.week, .month, .year]

    
    var selectedDay: Date {
        let date = Calendar.current.date(from: DateComponents(year: selectYear, month: selectMonth, day: selectDay))
        
        return date!
    }
    
    var selectedRow: Int?
    let actionTitle = ["Report Favorite Health Types",
                       "Report Selected Health Types",
                       "Report Based on Category"]
    
    var selectedTypes = Set<HKSampleType>()
    var selectedOption: PDFoption?
    
    var favType: [HKSampleType] {
        
        return ViewModels.favDataType
    }
    
    var start: Date {
        switch selectedRange {
        case .week:
            return Calendar.current.date(byAdding: .day, value: -6, to: selectedDay)!
        case .month:
            return beginOfMonth(year: selectYear, month: selectMonth)
        case .year:
            return beginOfYear(year: selectYear)
        }
    }
    
    var end: Date {
        switch selectedRange {
        case .week:
            return selectedDay
        case .month:
            return endOfMonth(year: selectYear, month: selectMonth)
        case .year:
            return endOfYear(year: selectYear)
        }
    }
    
    let allCategories = ViewModels.HealthCategories
    var allData: [HKSampleType] {
        var visited = Set<String>()
        var res: [HKSampleType] = []
        
        for category in ViewModels.HealthCategories {
            for type in category.dataTypes {
                if !visited.contains(type.identifier),
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
        
        datePicker.delegate = self
        datePicker.dataSource = self
        
        dateBtn.setTitle(selectedDayToString(), for: .normal)
        datePicker.selectRow(yearOption.firstIndex(of: selectYear)!, inComponent: 0, animated: false)
        datePicker.selectRow(monthOption.firstIndex(of: selectMonth)!, inComponent: 1, animated: false)
        datePicker.selectRow(selectDay - 1, inComponent: 2, animated: false)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
        view.isMultipleTouchEnabled = true
        tapGesture.delegate = self
        
        rangeView.layer.cornerRadius = 8
        dateView.layer.cornerRadius = 8
        
        setUpDropButton()
        setupRangePicker()
        
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
    
    func setupRangePicker() {
        let rangeClosure = { (action: UIAction) in
            switch action.title {
            case self.rangeOptions[0].rawValue:
                self.selectedRange = .week
            case self.rangeOptions[1].rawValue:
                self.selectedRange = .month
            case self.rangeOptions[2].rawValue:
                self.selectedRange = .year
            default:
                return
            }
            
            self.dateBtn.setTitle(self.selectedDayToString(), for: .normal)
            self.datePicker.reloadAllComponents()
        }
        
        let options = rangeOptions.map({ element in
            return UIAction(title: element.rawValue, handler: rangeClosure)
        })
        
        options[0].state = .on
        rangeBtn.changesSelectionAsPrimaryAction = true
        rangeBtn.showsMenuAsPrimaryAction = true
        rangeBtn.menu = UIMenu(title: "Choose time range", children: options)
    }
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
    
    func togglePickerView() {
        self.datePicker.isHidden.toggle()
    }
    
    func hidePickerView() {
        datePicker.isHidden = true
    }
    
    func selectedDayToString() -> String {
        let formatter = DateFormatter()
        switch selectedRange {
        case .week:
            formatter.dateFormat = "yyyy, MMM dd"
        case .month:
            formatter.dateFormat = "yyyy, MMM"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: selectedDay)
    }
    
    func numberOfDays(inMonth month: Int, forYear year: Int) -> Int {
        let current = Calendar.current
        if let date = current.date(from: DateComponents(year: year, month: month)),
           let range = current.range(of: .day, in: .month, for: date) {
            return range.count
        } else {
            return 0
        }
    }
    
    func endOfMonth(year: Int, month: Int) -> Date {
        let calendar = Calendar.current
        
        var endOfMonthComponents = DateComponents(year: year, month: month)
        endOfMonthComponents.day = calendar.range(of: .day, in: .month,
                                                  for: calendar.date(from: endOfMonthComponents)!)!.upperBound - 1
        
        return calendar.date(from: endOfMonthComponents)!
    }
    
    func endOfYear(year: Int) -> Date {
        let calendar = Calendar.current
        let endOfYearComponents = DateComponents(year: year, month: 12, day: 31)
        
        return calendar.date(from: endOfYearComponents)!
        
    }
    
    func beginOfMonth(year: Int, month: Int) -> Date {
        let calendar = Calendar.current
        let startOfMonthComponents = DateComponents(year: year, month: month, day: 1)
        
        return calendar.date(from: startOfMonthComponents)!
    }

    func beginOfYear(year: Int) -> Date {
        let calendar = Calendar.current
        let startOfYearComponents = DateComponents(year: year, month: 1, day: 1)
        
        return calendar.date(from: startOfYearComponents)!
    }
    
    @objc func tappedOutside(_ gesture: UITapGestureRecognizer) {
        hidePickerView()
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
    
    @IBAction func dateBtnTapped(_ sender: Any) {
        togglePickerView()
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
            previewVC?.range = selectedRange
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
        cell.isUserInteractionEnabled = true
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
        hidePickerView()
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

extension PDFPageViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch selectedRange {
        case .week:
            return 3
        case .month:
            return 2
        case .year:
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return yearOption.count
        }
        
        if component == 1 {
            return monthOption.count
        }
        
        if component == 2 {
            return numberOfDays(inMonth: selectMonth, forYear: selectYear)
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "\(yearOption[row])"
        }
        
        if component == 1 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            guard let monthDate = Calendar.current.date(from: DateComponents(month: monthOption[row])) else {
                return nil
            }
            
            return dateFormatter.string(from: monthDate)
        }
        
        if component == 2 {
            return "\(row + 1)"
        }
        
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectYear = yearOption[row]
        }
        
        if component == 1 {
            selectMonth = monthOption[row]
        }
        
        if component == 2 {
            selectDay = row + 1
        }
        
        dateBtn.setTitle(selectedDayToString(), for: .normal)
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 0 {
            return pickerView.frame.width / 3.0
        }
        
        if component == 2 {
            return pickerView.frame.width / 5.0
        }
        
        if component == 1 {
            return pickerView.frame.width * (7.0 / 15.0)
        }
        
        return 0
    }
}

extension PDFPageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let view = touch.view, view.isDescendant(of: tableView) {
            return false
        }
        
        return true
    }
}

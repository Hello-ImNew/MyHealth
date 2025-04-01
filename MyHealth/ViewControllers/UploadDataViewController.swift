//
//  UploadDataViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 3/14/24.
//

import UIKit
import HealthKit

struct quantityPayload: Encodable {
    let userID: String
    let identifier: String
    let start: String
    let end: String
    let data: [quantityDataValue]
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_ID"
        case identifier = "identifier"
        case start = "start_date"
        case end = "end_date"
        case data = "health_data"
    }
}

struct categoryPayload: Encodable {
    let userID: String
    let identifier: String
    let start: String
    let end: String
    let data: [categoryDataValue]
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_ID"
        case identifier = "identifier"
        case start = "start_date"
        case end = "end_date"
        case data = "health_data"
    }
}

class UploadDataViewController: UIViewController {
    
    @IBOutlet weak var btnSelectDate: UIButton!
    @IBOutlet weak var datePicker: UIPickerView!
    @IBOutlet weak var rangePicker: UIButton!
    @IBOutlet weak var rangeView: UIView!
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionBtn: UIButton!
    
    let identifier = HKQuantityTypeIdentifier.stepCount.rawValue
    
    var selectedOption: UploadOption?
    
    let favType = ViewModels.favDataType
    let allCategories = ViewModels.HealthCategories
    var allData: [HKSampleType] {
        var visited = Set<String>()
        var res: [HKSampleType] = []
        
        for category in ViewModels.HealthCategories {
            for type in category.dataTypes {
                if !visited.contains(type.identifier) {
                    visited.insert(type.identifier)
                    res.append(type)
                }
            }
        }
        
        return res
    }
    
    var selectedTypes = Set<HKSampleType>()
    var selectedRow: Int?
    
    var selectedRange: rangeOption = .week
    var selectDay: Int = Calendar.current.component(.day, from: Date())
    var selectMonth: Int = Calendar.current.component(.month, from: Date())
    var selectYear: Int = Calendar.current.component(.year, from: Date())
    var selectedDay: Date {
        let date = Calendar.current.date(from: DateComponents(year: selectYear, month: selectMonth, day: selectDay))
        
        return date!
    }
    
    var start: Date {
        
        let res: Date
        switch selectedRange {
        case .week:
            res = Calendar.current.date(byAdding: .day, value: -6, to: selectedDay)!
        case .month:
            res = beginOfMonth(year: selectYear, month: selectMonth)
        case .year:
            res = beginOfYear(year: selectYear)
        }
        return res
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
    let yearOption: [Int] = Array(2015...(Calendar.current.component(.year, from: Date()) + 5))
    let monthOption: [Int] = Array(1...12)
    let rangeOptions: [rangeOption] = [.week, .month, .year]
    
    enum rangeOption: String {
        case week = "1 Week"
        case month = "1 Month"
        case year = "1 Year"
    }
    
    enum UploadOption {
        case fav
        case selectType
        case selectCategory
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        datePicker.delegate = self
        datePicker.dataSource = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        btnSelectDate.setTitle(selectedDayToString(), for: .normal)
        datePicker.selectRow(yearOption.firstIndex(of: selectYear)!, inComponent: 0, animated: false)
        datePicker.selectRow(monthOption.firstIndex(of: selectMonth)!, inComponent: 1, animated: false)
        datePicker.selectRow(selectDay - 1, inComponent: 2, animated: false)
        
        setupRangePicker()
        setupOptionbtn()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
        
        rangeView.layer.cornerRadius = 8
        dateView.layer.cornerRadius = 8
    }
    
    func uploadQuantityData(for identifier: String, _ completion: @escaping (Bool) -> Void) {
        guard let id = ViewModels.userID else {
            showAlert(title: "No User ID", message: "No user ID saved")
            return
        }
        
        let healthStore = HealthData.healthStore
        let current = Calendar.current
        
        let startQueryDate = current.startOfDay(for: start)
        let endQueryDate = current.date(bySettingHour: 23, minute: 59, second: 59, of: end)!
        
        let quantityType = HKQuantityType(HKQuantityTypeIdentifier(rawValue: identifier))
        let predicate = HKQuery.predicateForSamples(withStart: startQueryDate, end: endQueryDate)
        let options = getStatisticsOptions(for: identifier)
        let anchorDate = createAnchorDate(for: startQueryDate)
        let interval = DateComponents(day: 1)
        
        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options, anchorDate: anchorDate, intervalComponents: interval)
        let updateInterfaceWithStaticstics: (HKStatisticsCollection) -> [quantityDataValue] = { staticsticsCollection in
            var dataValues: [quantityDataValue] = []
            
            let startDate = startQueryDate
            let endDate = endQueryDate
            
            staticsticsCollection.enumerateStatistics(from: startDate, to: endDate) { (staticstics, stop) in
                if let quantity = getStatisticsQuantity(for: staticstics, with: options),
                   let unit = preferredUnit(for: identifier) {
                    var value = quantity.doubleValue(for: unit)
                    if unit == .percent() {
                        value *= 100
                    }
                    
                    let dataValue = quantityDataValue(identifier: identifier, startDate: staticstics.startDate, endDate: staticstics.endDate, value: value)
                    
                    dataValues.append(dataValue)
                }
            }
            return dataValues
        }
        
        query.initialResultsHandler = {query, statisticsCollection, error in
            if let statisticsCollection = statisticsCollection {
                let dataValues = updateInterfaceWithStaticstics(statisticsCollection)
                
                let link = newServiceURL + "upload/add_quantity_data.php"
                let url  = URL(string: link)
                guard let url = url else {
                    print("Cannot connect to web service.")
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                do {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                    let startStr = formatter.string(from: startQueryDate)
                    let endStr = formatter.string(from: endQueryDate)
                    
                    let payload = quantityPayload(userID: id,
                                                identifier: identifier,
                                                start: startStr,
                                                end: endStr,
                                                data: dataValues)
                    let jsonData = try JSONEncoder().encode(payload)
                    request.httpBody = jsonData
                } catch {
                    fatalError("Error encoding data: \(error)")
                }
                
                ViewModels.sharedSession.dataTask(with: request) { (data, response, error) in
                    guard let data = data,
                          error == nil else {
                        self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                        completion(false)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        self.showAlert(title: "Server Error", message: "Error uploading data for \(identifier)")
                        let result = String(data: data, encoding: .utf8)
                        completion(false)
                        
                        return
                    }
                    
                    completion(true)
                    
                    print("Success")
                }.resume()
            }
        }
        
        healthStore.execute(query)
    }
    
    func uploadCategoryData(for identifier: String, _ completion: @escaping (Bool) -> Void) {
        guard let id = ViewModels.userID else {
            showAlert(title: "No User ID", message: "No user ID saved")
            return
        }
        
        let healthStore = HealthData.healthStore
        let current = Calendar.current
        let startQueryDate: Date
        let endQueryDate: Date
        
        if identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
            startQueryDate = current.date(byAdding: .hour, value: -6, to: current.startOfDay(for: start))!
            endQueryDate = current.date(bySettingHour: 18, minute: 00, second: 00, of: end)!
        } else {
            startQueryDate = current.startOfDay(for: start)
            endQueryDate = current.date(bySettingHour: 23, minute: 59, second: 59, of: end)!
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startQueryDate, end: endQueryDate, options: [])
        let sampletype = getSampleType(for: identifier)!
        
        let query = HKSampleQuery(sampleType: sampletype, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { query, result, error in
            if let error = error {
                print("Error fetching data for \(sampletype.identifier): \(error.localizedDescription)")
            } else {
                if let results = result as? [HKCategorySample] {
                    let dataValues = results.compactMap({ element in
                        let dataValue = categoryDataValue(identifier: identifier,
                                                          startDate: element.startDate,
                                                          endDate: element.endDate,
                                                          value: element.value)
                        
                        return dataValue
                    })
                    
                    let link = newServiceURL + "upload/add_category_data.php"
                    let url = URL(string:  link)
                    
                    guard let url = url else {
                        print("Cannot connect to web service.")
                        return
                    }
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    do {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                        let startStr = formatter.string(from: startQueryDate)
                        let endStr = formatter.string(from: endQueryDate)
                        
                        let payload = categoryPayload(userID: id,
                                                      identifier: identifier,
                                                      start: startStr,
                                                      end: endStr,
                                                      data: dataValues)
                        
                        let jsonData = try JSONEncoder().encode(payload)
                        request.httpBody = jsonData
                    } catch {
                        fatalError("Error encoding data: \(error)")
                    }
                    
                    ViewModels.sharedSession.dataTask(with: request) { (data, response, error) in
                        guard let data = data,
                              error == nil else {
                            self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                            completion(false)
                            return
                        }
                        
                        guard let httpResponse = response as? HTTPURLResponse,
                              (200...299).contains(httpResponse.statusCode) else {
                            self.showAlert(title: "Server Error", message: "Error upload data for \(identifier)")
                            let result = String(data: data, encoding: .utf8)
                            print(data)
                            completion(false)
                            return
                        }
                        completion(true)
                        print("Success")
                    }.resume()
                }
            }
        })
        
        healthStore.execute(query)
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
            
            self.btnSelectDate.setTitle(self.selectedDayToString(), for: .normal)
            self.datePicker.reloadAllComponents()
            
            self.datePicker.reloadAllComponents()
//            self.datePicker.selectRow(self.yearOption.firstIndex(of: self.selectYear)!, inComponent: 0, animated: false)
//            self.datePicker.selectRow(self.monthOption.firstIndex(of: self.selectMonth)!, inComponent: 1, animated: false)
//            self.datePicker.selectRow(self.selectDay - 1, inComponent: 2, animated: false)
        }
        
        let options = rangeOptions.map({ element in
            return UIAction(title: element.rawValue, handler: rangeClosure)
        })
        
        options[0].state = .on
        rangePicker.changesSelectionAsPrimaryAction = true
        rangePicker.showsMenuAsPrimaryAction = true
        rangePicker.menu = UIMenu(title: "Choose time range", children: options)
    }
    
    func setupOptionbtn() {
        let actionTitle = ["Report Favorite Health Types",
                           "Report Selected Health Types",
                           "Report Based on Category"]
        
        let optionClosure = {(action: UIAction) in
            switch action.title {
            case actionTitle[0]:
                self.selectedOption = .fav
            case actionTitle[1]:
                self.selectedOption = .selectType
            case actionTitle[2]:
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
        optionBtn.changesSelectionAsPrimaryAction = true
        optionBtn.showsMenuAsPrimaryAction = true
        optionBtn.menu = UIMenu(title: "Report Options", children: options)
    }
    
    @objc func tappedOutside(_ gesture: UITapGestureRecognizer) {
        hidePickerView()
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
    
    func togglePickerView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.datePicker.isHidden.toggle()
        })
    }
    
    func hidePickerView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.datePicker.isHidden = true
        })
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
    
    @IBAction func dateTapped(_ sender: Any) {
        togglePickerView()
    }
    
    @IBAction func uploadTapped(_ sender: Any) {
        switch selectedOption {
        case .fav:
            selectedTypes = Set(favType)
        case .selectType:
            if selectedTypes.isEmpty {
                return
            }
        case .selectCategory:
            if let selectedRow = selectedRow {
                selectedTypes = Set(allCategories[selectedRow].dataTypes)
            } else {
                return
            }
        case nil:
            return
        }
        var allSuccess = true
        let group = DispatchGroup()
        group.enter()
        HealthData.requestHealthDataAccessIfNeeded(toShare: nil, read: selectedTypes, completion: { success in
            if success {
                for type in self.selectedTypes {
                    group.enter()
                    if type is HKQuantityType {
                        self.uploadQuantityData(for: type.identifier) { success in
                            allSuccess = allSuccess && success
                            group.leave()
                        }
                    }
                    if type is HKCategoryType {
                        self.uploadCategoryData(for: type.identifier) { success in
                            allSuccess = allSuccess && success
                            group.leave()
                        }
                    }
                }
            }
            group.leave()
        })
        
        group.notify(queue: .main, execute: {
            if allSuccess {
                self.showAlert(title: "Upload Completed", message: "Thank you for uploading your health data.")
            } else {
                self.showAlert(title: "Upload Incompleted", message: "Some data types did not upload completely.")
            }
        })
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

extension UploadDataViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
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
        
        btnSelectDate.setTitle(selectedDayToString(), for: .normal)
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

extension UploadDataViewController: UITableViewDataSource, UITableViewDelegate {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "DataTypeCell", for: indexPath)
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

extension UploadDataViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let view = touch.view, view.isDescendant(of: tableView) {
            return false
        }
        
        return true
    }
}

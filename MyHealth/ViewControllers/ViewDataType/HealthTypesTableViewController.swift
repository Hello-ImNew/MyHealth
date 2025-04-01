//
//  HealthTypesTableViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 9/29/23.
//

import UIKit
import HealthKit
import SwiftUI

struct favType: Codable {
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case type = "fav_health_type"
    }
}

struct dataAvailability {
    let displayName: String
    var dataValue: [HealthDataValue] = []
}

class HealthTypesTableViewController: UITableViewController {
    
    let healthStore = HealthData.healthStore
    var healthDataTypes: [HKSampleType] = ViewModels.favDataType
    var dataTypeAvailability: [dataAvailability] = []
    var currentTitle: String = "Favorites Health Types"
    var isFavView = true
    var noFavMessage = "No Favorites Data Types Selected."

    override func viewDidLoad() {
        super.viewDidLoad()
        dataTypeAvailability = [dataAvailability(displayName: "Today"), dataAvailability(displayName: "Last 7 Days"), dataAvailability(displayName: "Last 30 Days"), dataAvailability(displayName: "Older"),dataAvailability(displayName: "No Data Available")]
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        if isFavView {
            self.navigationItem.leftBarButtonItem = self.editButtonItem
        }
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.title = currentTitle
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addProfilePicture()
        
        if isFavView {
            if ViewModels.isOnline {
                let group = DispatchGroup()
                group.enter()
                getFavData{ success in
                    if success {
                        self.healthDataTypes = ViewModels.favDataType
                    }
                    group.leave()
                }
                group.wait()
            } else {
                self.healthDataTypes = ViewModels.favDataType
            }
        }
        
        if healthDataTypes.isEmpty {
            reloadTable(noFavMessage)
            return
        }
        let read = Set(healthDataTypes)
        let share = Set(healthDataTypes)
        HealthData.requestHealthDataAccessIfNeeded(toShare: share, read: read) { success in
            if success {
                self.checkDataAvailability(dataTypesToCheck: self.healthDataTypes) {
                    self.sortDataValue()
                    self.reloadTable(self.noFavMessage)
                }
            }
        }
    }
    
    
    func checkDataAvailability(dataTypesToCheck: [HKSampleType], completion: @escaping () -> Void) {
        clearDataTypes()
        let group = DispatchGroup()
        for dataType in dataTypesToCheck {
            if dataType.identifier == HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue {
                continue
            }
            let type = dataType
            group.enter()
            
            // Create a predicate to specify the time range you want to check
            let datePredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
            
            // Create a query to fetch data for the specified data type
            let query = HKSampleQuery(sampleType: type, predicate: datePredicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { (query, results, error) in
                if let error = error {
                    print("Error fetching data for \(type): \(error.localizedDescription)")
                    group.leave()
                } else {
                    if let result = results?.first {
                        if type is HKQuantityType {
                            
                            let latestDate = result.startDate
                            let calendar = Calendar.current
                            
                            let startOfDay = calendar.startOfDay(for: latestDate)
                            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
                            
                            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
                            let quantityType = HKQuantityType(HKQuantityTypeIdentifier(rawValue: type.identifier))
                            let option = getStatisticsOptions(for: type.identifier)
                            //
                            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: option) { (query, statisticResult, error) in
                                if let statisticResult = statisticResult,
                                   let quantity = getStatisticsQuantity(for: statisticResult, with: option),
                                   let unit = preferredUnit(for: type.identifier) {
                                    var value = quantity.doubleValue(for: unit)
                                    if unit == .percent() {
                                        value *= 100
                                    }
                                    
                                    var index = 0
                                    if statisticResult.endDate.isToday {
                                        index = 0
                                    } else if statisticResult.endDate.isWithinLast7Days! {
                                        index = 1
                                    } else if statisticResult.endDate.isWithinLast30Days! {
                                        index = 2
                                    } else {
                                        index = 3
                                    }
                                    let dataValue = quantityDataValue(identifier: type.identifier, startDate: statisticResult.startDate, endDate: result.endDate, value: value)
                                    
                                    // if the datatype is boold pressure, get the diastolic value
                                    if type.identifier == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue {
                                        let quantityType = HKQuantityType(HKQuantityTypeIdentifier(rawValue: HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue))
                                        let option = getStatisticsOptions(for: quantityType.identifier)
                                        let secondQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: option) { (query, statisticResult, error) in
                                            if let statisticResult = statisticResult,
                                               let quantity = getStatisticsQuantity(for: statisticResult, with: option),
                                               let unit = preferredUnit(for: type.identifier) {
                                                var value = quantity.doubleValue(for: unit)
                                                if unit == .percent() {
                                                    value *= 100
                                                }
                                                dataValue.secondaryValue = value
                                                
                                                
                                                
                                                DispatchQueue.main.async {
                                                    self.insertToDataTypes(dataValue: dataValue, at: index)
                                                    self.reloadTable(self.noFavMessage)
                                                    group.leave()
                                                }
                                            }
                                        }
                                        
                                        self.healthStore.execute(secondQuery)
                                    } else {
                                        
                                        
                                        DispatchQueue.main.async {
                                            self.dataTypeAvailability[index].dataValue.append(dataValue)
                                            group.leave()
                                        }
                                    }
                                    
                                } else if let error = error {
                                    // Handle any errors that occurred during the query.
                                    print("Error fetching heart rate data: \(error.localizedDescription)")
                                    group.leave()
                                }
                            }
                            
                            self.healthStore.execute(query)
                        } else if let result = result as? HKCategorySample {
                            print(type.identifier)
                            let dataValue = categoryDataValue(identifier: type.identifier, startDate: result.startDate, endDate: result.endDate, value: result.value)
                            var index: Int
                            if dataValue.endDate.isToday {
                                index = 0
                            } else if dataValue.endDate.isWithinLast7Days! {
                                index = 1
                            } else if dataValue.endDate.isWithinLast30Days! {
                                index = 2
                            } else {
                                index = 3
                            }
                            
                            DispatchQueue.main.async {
                                self.dataTypeAvailability[index].dataValue.append(dataValue)
                                group.leave()
                            }
                        }
                        
                        
                    } else {
                        DispatchQueue.main.async {
                            let emptyDatavalue = HealthDataValue(identifier: type.identifier, startDate: Date(), endDate: Date())
                            self.dataTypeAvailability[4].dataValue.append(emptyDatavalue)
                            group.leave()
                        }
                    }
                }
            }
            
            // Execute the query
            healthStore.execute(query)
            
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    func getFavData(_ completion: @escaping (_ success: Bool) -> Void) {
        
        let link = newServiceURL + "fav_data/get_fav_data.php"
        
        guard let url = URL(string: link) else {
            print("Cannot connect to web service.")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = [
                "user_ID": ViewModels.userID
            ]
            
            let jsondata = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsondata
        } catch {
            print("Error encoding data: \(error)")
            completion(false)
            return
        }
        
        ViewModels.sharedSession.dataTask(with: request) {(data, response, error) in
            guard error == nil,
                  let data = data else {
                print("Error: \(error!)")
                self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Server error: \(String(data: data, encoding: .utf8) ?? "")")
                completion(false)
                return
            }
            do {
                let result = String(data: data, encoding: .utf8)
                print(String(data: data, encoding: .utf8))
                let items = try JSONDecoder().decode([favType].self, from: data)
                let types = items.map({$0.type})
                ViewModels.favHealthTypes = types
                completion(true)
            } catch {
                print("error decoding data: \(error.localizedDescription)")
                completion(false)
            }
        }.resume()
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataTypeAvailability[section].dataValue.count
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if dataTypeAvailability[section].dataValue.isEmpty {
            print("Section \(section)")
            return nil
        } else {
            let header = dataTypeAvailability[section].displayName
            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
            
            let label = UILabel()
            label.frame = CGRect.init(x: 5, y: 5, width: headerView.frame.width-10, height: headerView.frame.height-10)
            label.text = header
            label.font = .systemFont(ofSize: 25)
            label.textColor = .secondaryLabel
            label.center = headerView.center
            
            headerView.addSubview(label)
            headerView.backgroundColor = tableView.backgroundColor
            
            
            return headerView
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataTypeAvailability[section].dataValue.isEmpty {
            return 0
        } else {
            return 50
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let datasource = dataTypeAvailability[indexPath.section]
        let dataValue = datasource.dataValue[indexPath.row]
        let identifier = dataValue.identifier
            
        // Quantity Type Data
        if let dataValue = dataValue as? quantityDataValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DataAvailableHealthTypeCell", for: indexPath) as! AvailableDataTypeTableViewCell
            
            // Configure the cell...
            cell.txtLabel?.text = getDataTypeName(for: identifier)
            cell.imgIcon.image = UIImage(systemName: getDataTypeIcon(for: identifier)!)
            cell.txtData?.text = "\(dataValue.displayString) \(getUnit(for: identifier)!)"
            cell.txtDate?.text = dataValue.endDate.toString
            cell.imgIcon.tintColor = getDataTypeColor(for: identifier)
            cell.txtLabel.textColor = getDataTypeColor(for: identifier)
            
            if indexPath.section == 0 || indexPath.section == 1 {
                var summaryData : [quantityDataValue] = []
                let start : Date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date())!)
                let end : Date = Date()
                
                performQuery(for: identifier, from: start, to: end) { result in
                    DispatchQueue.main.async {
                        summaryData = result
                        cell.chartView.subviews.forEach({$0.removeFromSuperview()})
                        let summaryChartView = SummaryChartView(dataIdentifier: identifier, data: summaryData)
                        let summaryChartUIView = UIHostingController(rootView: summaryChartView)
                        summaryChartUIView.view.translatesAutoresizingMaskIntoConstraints = false
                        cell.chartView.addSubview(summaryChartUIView.view)
                        
                        NSLayoutConstraint.activate([
                            summaryChartUIView.view.centerXAnchor.constraint(equalTo: cell.chartView.centerXAnchor),
                            summaryChartUIView.view.centerYAnchor.constraint(equalTo: cell.chartView.centerYAnchor)
                        ])
                    }
                }
            } else {
                cell.chartView.subviews.forEach({$0.removeFromSuperview()})
            }
            
            return cell
        } else  
        // Category Type Data
        if let dataValue = dataValue as? categoryDataValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryDataCell", for: indexPath) as! CategoryDataTableViewCell
            
            //if data is a notification type data
            if ViewModels.notificationType.contains(where: {$0 == identifier}) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM dd, yyyy hh:mm"
                
                cell.imgIcon.image = UIImage(systemName: getDataTypeIcon(for: identifier)!)
                cell.imgIcon.tintColor = getDataTypeColor(for: identifier)
                cell.txtTime.text = ""
                cell.txtData.text = formatter.string(from: dataValue.startDate)
                cell.txtName.text = getDataTypeName(for: identifier)
                cell.txtName.textColor = getDataTypeColor(for: identifier)
                
                return cell
            }
            
            cell.imgIcon.image = UIImage(systemName: getDataTypeIcon(for: identifier)!)
            cell.imgIcon.tintColor = getDataTypeColor(for: identifier)
            cell.txtName.text = getDataTypeName(for: identifier)
            cell.txtName.textColor = getDataTypeColor(for: identifier)
            cell.txtData.text = getCategoryValues(for: identifier)[dataValue.value]
            cell.txtTime.text = dataValue.endDate.toString
            
            // if data is a single value data type
            if ViewModels.categoryValueType.contains(where: {$0 == identifier}) {
                let current = Calendar.current
                let start = current.startOfDay(for: dataValue.startDate)
                let end = current.date(bySettingHour: 23, minute: 59, second: 59, of: dataValue.startDate)
                let datatype = getSampleType(for: identifier)!
                let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
                let query = HKSampleQuery(sampleType: datatype, predicate: datePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { (query, results, error) in
                    if let error = error {
                        print("Error fetching data for \(identifier): \(error.localizedDescription)")
                    } else {
                        if let results = results as? [HKCategorySample] {
                            let time = self.totalTime(results.compactMap({categoryDataValue(identifier: identifier, startDate: $0.startDate, endDate: $0.endDate, value: $0.value)}))
                            let hr = Int(time / 3600)
                            let min = Int((time % 3600) / 60)
                            let sec = Int(time % 60)
                            
                            let attr1 = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)]
                            let attr2 = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)]
                            
                            let attributedString = NSMutableAttributedString(string: "")
                            
                            if hr > 0 {
                                attributedString.append(NSAttributedString(string: "\(hr)", attributes: attr1))
                                attributedString.append(NSAttributedString(string: " hr ", attributes: attr2))
                            }
                            
                            if min > 0 {
                                attributedString.append(NSAttributedString(string: "\(min)", attributes: attr1))
                                attributedString.append(NSAttributedString(string: " min ", attributes: attr2))
                            }
                            
                            if sec > 0 {
                                attributedString.append(NSAttributedString(string: "\(sec)", attributes: attr1))
                                attributedString.append(NSAttributedString(string: " sec ", attributes: attr2))
                            }
                            
                            DispatchQueue.main.async {
                                cell.txtData.attributedText = attributedString
                            }
                        }
                    }
                    
                })
                
                healthStore.execute(query)
            }
            
            // If data is sleep analysis
            if identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
                let current = Calendar.current
                let start: Date?
                let end: Date?
                let startOfDate = current.date(bySettingHour: 18, minute: 0, second: 0, of: dataValue.startDate)
                if dataValue.startDate >= startOfDate! {
                    start = startOfDate
                    end = current.date(byAdding: .day, value: 1, to: start!)
                } else {
                    end = startOfDate
                    start = current.date(byAdding: .day, value: -1, to: end!)
                }
                let dataType = getSampleType(for: identifier)!
                let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
                let query = HKSampleQuery(sampleType: dataType, predicate: datePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { (query, results, error) in
                    if let error = error {
                        print("Error fetching data for \(identifier): \(error.localizedDescription)")
                    } else {
                        if let results = results as? [HKCategorySample] {
                            let data = results.compactMap({categoryDataValue(identifier: identifier, from: $0)})
                            let intervals = mergeTimeIntervals(data: data)
                            var time: Int {
                                var result = 0.0
                                for (start, end) in intervals {
                                    result += end.timeIntervalSince(start)
                                }
                                
                                return Int(result)
                            }
                            let hr = Int(time / 3600)
                            let min = Int((time % 3600) / 60)
                            let sec = Int(time % 60)
                            
                            let attr1 = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)]
                            let attr2 = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)]
                            
                            let attributedString = NSMutableAttributedString(string: "")
                            
                            if hr > 0 {
                                attributedString.append(NSAttributedString(string: "\(hr)", attributes: attr1))
                                attributedString.append(NSAttributedString(string: " hr ", attributes: attr2))
                            }
                            
                            if min > 0 {
                                attributedString.append(NSAttributedString(string: "\(min)", attributes: attr1))
                                attributedString.append(NSAttributedString(string: " min ", attributes: attr2))
                            }
                            
                            if sec > 0 {
                                attributedString.append(NSAttributedString(string: "\(sec)", attributes: attr1))
                                attributedString.append(NSAttributedString(string: " sec ", attributes: attr2))
                            }
                            
                            DispatchQueue.main.async {
                                cell.txtData.attributedText = attributedString
                            }
                        }
                    }
                })
                
                healthStore.execute(query)
            }
            
            return cell
        } else {
            let sampleType = getSampleType(for: identifier)
            let cell: HealthTypeTableViewCell
            if sampleType is HKQuantityType {
                cell = tableView.dequeueReusableCell(withIdentifier: "QuantityEmptyCell", for: indexPath) as! HealthTypeTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "CategoryEmptyCell", for: indexPath) as! HealthTypeTableViewCell
            }
            
            cell.txtTitle.text = getDataTypeName(for: identifier)
            cell.imgIcon.image = UIImage(systemName: getDataTypeIcon(for: identifier)!)
            cell.imgIcon.tintColor = getDataTypeColor(for: identifier)
            
            return cell
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let datasource = dataTypeAvailability[indexPath.section]
            let dataType = (datasource.dataValue[indexPath.row]).identifier
            ViewModels.removeFavHealthType(for: dataType)
            dataTypeAvailability[indexPath.section].dataValue.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    func insertToDataTypes(dataValue: HealthDataValue, at index: Int){
        let i = self.dataTypeAvailability[index].dataValue.lastIndex(where: {getDataTypeName(for: $0.identifier) ?? "" < getDataTypeName(for: dataValue.identifier) ?? ""}) ?? -1
        self.dataTypeAvailability[index].dataValue.insert(dataValue, at: i+1)
    }
    
    func sortDataValue() {
        for i in 0..<dataTypeAvailability.count {
            dataTypeAvailability[i].dataValue.sort(by: {
                let title1 = getDataTypeName(for: $0.identifier)!
                let title2 = getDataTypeName(for: $1.identifier)!
                
                return title1 < title2
            })
        }
    }
    
    func clearDataTypes() {
        for i in 0..<dataTypeAvailability.count{
            dataTypeAvailability[i].dataValue.removeAll()
        }
    }
    
    func reloadTable(_ message: String = "No Data"){
        if healthDataTypes.count == 0 {
            setEmptyDataView(message)
            tableView.reloadData()
        } else {
            tableView.backgroundView = nil
            tableView.reloadData()
        }
    }
    
    func setEmptyDataView(_ message: String) {
        let emptyDataView = EmptyDataBackgroundView(message: message)
        tableView.backgroundView = emptyDataView
    }

    func totalTime(_ data: [categoryDataValue]) -> Int {
        var sum = 0
        data.forEach({
            sum += Int($0.endDate.timeIntervalSince($0.startDate))
        })
        return sum
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "ShowHealthDataSegue" || segue.identifier == "ShowEmptyhealthDataSegue") {
            let healthDisplayController = segue.destination as? HealthDisplayViewController
            let selectedCell = self.tableView.indexPath(for: sender as! UITableViewCell)
            let selectedRow = selectedCell?.row
            let dataType = self.dataTypeAvailability[selectedCell!.section].dataValue[selectedRow!].identifier
            healthDisplayController?.dataTypeIdentifier = dataType
        } else if (segue.identifier == "ShowCategoryDataSegue") {
            let categoryDisplayController = segue.destination as? CategoryDisplayViewController
            let selectedCell = self.tableView.indexPath(for: sender as! UITableViewCell)
            let selectedRow = selectedCell?.row
            let selectedSection = selectedCell?.section
            let selectedCategory = self.dataTypeAvailability[selectedSection!].dataValue[selectedRow!].identifier
            categoryDisplayController?.dataTypeIdentifier = selectedCategory
        }
    }
    

}

//
//  HealthTypesTableViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 9/29/23.
//

import UIKit
import HealthKit
import SwiftUI

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
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.title = currentTitle
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isFavView {
            healthDataTypes = ViewModels.favDataType
        }
        
        if healthDataTypes.isEmpty {
            reloadTable(noFavMessage)
            return
        }
        
        let read = Set(healthDataTypes)
        HealthData.requestHealthDataAccessIfNeeded(toShare: nil, read: read) { success in
            if success {
                self.checkDataAvailability(dataTypesToCheck: self.healthDataTypes)
            }
        }
    }
    
    
    func checkDataAvailability(dataTypesToCheck: [HKSampleType]) {
        clearDataTypes()
        for dataType in dataTypesToCheck {
            if dataType.identifier == HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue {
                continue
            }
            // Create a predicate to specify the time range you want to check
            let datePredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)

            // Create a query to fetch data for the specified data type
            let query = HKSampleQuery(sampleType: dataType, predicate: datePredicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { (query, results, error) in
                if let error = error {
                    print("Error fetching data for \(dataType): \(error.localizedDescription)")
                } else {
                    if let result = results?.first {
                        
                        let latestDate = result.startDate
                        let calendar = Calendar.current
                        
                        let startOfDay = calendar.startOfDay(for: latestDate)
                        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
                        
                        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
                        let quantityType = HKQuantityType(HKQuantityTypeIdentifier(rawValue: dataType.identifier))
                        let option = getStatisticsOptions(for: dataType.identifier)
//
                        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: option) { (query, statisticResult, error) in
                            if let statisticResult = statisticResult,
                                let quantity = getStatisticsQuantity(for: statisticResult, with: option),
                                let unit = preferredUnit(for: dataType.identifier) {
                                var value = quantity.doubleValue(for: unit)
                                if unit == .percent() {
                                    value *= 100
                                }
                                
                                var index = 0
                                if statisticResult.startDate.isToday {
                                    index = 0
                                } else if statisticResult.startDate.isWithinLast7Days! {
                                    index = 1
                                } else if statisticResult.startDate.isWithinLast30Days! {
                                    index = 2
                                } else {
                                    index = 3
                                }
                                var dataValue = HealthDataValue(identifier: dataType.identifier, startDate: statisticResult.startDate, endDate: result.endDate, value: value)
                                
                                // if the datatype is boold pressure, get the diastolic value
                                if dataType.identifier == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue {
                                    let quantityType = HKQuantityType(HKQuantityTypeIdentifier(rawValue: HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue))
                                    let option = getStatisticsOptions(for: quantityType.identifier)
                                    let secondQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: option) { (query, statisticResult, error) in
                                        if let statisticResult = statisticResult,
                                           let quantity = getStatisticsQuantity(for: statisticResult, with: option),
                                           let unit = preferredUnit(for: dataType.identifier) {
                                            var value = quantity.doubleValue(for: unit)
                                            if unit == .percent() {
                                                value *= 100
                                            }
                                            dataValue.secondaryValue = value
                                            
                                            self.dataTypeAvailability[index].dataValue.append(dataValue)
                                            
                                            DispatchQueue.main.async {
                                                self.reloadTable(self.noFavMessage)
                                            }
                                        }
                                    }
                                    
                                    self.healthStore.execute(secondQuery)
                                } else {
                                    self.dataTypeAvailability[index].dataValue.append(dataValue)
                                    
                                    DispatchQueue.main.async {
                                        self.reloadTable(self.noFavMessage)
                                    }
                                }
                                
                            } else if let error = error {
                                // Handle any errors that occurred during the query.
                                print("Error fetching heart rate data: \(error.localizedDescription)")
                            }
                        }
                        
                        self.healthStore.execute(query)
                        
                        
                    } else {
                        let emptyDatavalue = HealthDataValue(identifier: dataType.identifier, startDate: Date(), endDate: Date(), value: 0)
                        self.dataTypeAvailability[4].dataValue.append(emptyDatavalue)
                        
                        DispatchQueue.main.async {
                            self.reloadTable(self.noFavMessage)
                        }
                    }
                }
            }
            
            // Execute the query
            healthStore.execute(query)
        }
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
        if dataTypeAvailability[indexPath.section].dataValue.isEmpty {
            print("Section \(indexPath.section), row \(indexPath.row)")
        }
        if indexPath.section == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HealthTypeCell", for: indexPath) as! HealthTypeTableViewCell
            let datasource = dataTypeAvailability[indexPath.section].dataValue
            let dataType = (datasource[indexPath.row]).identifier
            // Configure the cell...
            cell.txtTitle?.text = getDataTypeName(for: dataType)
            cell.imgIcon.image = UIImage(systemName: getDataTypeIcon(for: dataType)!)
            cell.backgroundColor = tableView.backgroundColor
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DataAvailableHealthTypeCell", for: indexPath) as! AvailableDataTypeTableViewCell
            let datasource = dataTypeAvailability[indexPath.section]
            let dataType = (datasource.dataValue[indexPath.row]).identifier
            let dataValue = datasource.dataValue[indexPath.row]
            
            let dateformatter = DateFormatter()
            if indexPath.section == 0 {
                dateformatter.dateFormat = "hh:mm"
            } else {
                dateformatter.dateFormat = "dd/MM/yyyy"
            }
            // Configure the cell...
            cell.txtLabel?.text = getDataTypeName(for: dataType)
            cell.imgIcon.image = UIImage(systemName: getDataTypeIcon(for: dataType)!)
            cell.txtData?.text = "\(dataValue.displayString) \(getUnit(for: dataType)!)"
            cell.txtDate?.text = dateformatter.string(from: dataValue.endDate)
            
            if indexPath.section == 0 || indexPath.section == 1 {
                var summaryData : [HealthDataValue] = []
                let start : Date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date())!)
                let end : Date = Date()
                
                performQuery(for: dataType, from: start, to: end) { result in
                    DispatchQueue.main.async {
                        summaryData = result
                        cell.chartView.subviews.forEach({$0.removeFromSuperview()})
                        let summaryChartView = SummaryChartView(dataIdentifier: dataType, data: summaryData)
                        let summaryChartUIView = UIHostingController(rootView: summaryChartView)
                        summaryChartUIView.view.translatesAutoresizingMaskIntoConstraints = false
                        cell.chartView.addSubview(summaryChartUIView.view)
                        
                        NSLayoutConstraint.activate([
                            summaryChartUIView.view.centerXAnchor.constraint(equalTo: cell.chartView.centerXAnchor),
                            summaryChartUIView.view.centerYAnchor.constraint(equalTo: cell.chartView.centerYAnchor)
                        ])
                    }
                }
            }
            
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

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
            sortDataAvailability(for: &dataTypeAvailability) {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func setEmptyDataView(_ message: String) {
        let emptyDataView = EmptyDataBackgroundView(message: message)
        tableView.backgroundView = emptyDataView
    }
    
    func sortDataAvailability(for dataInput: inout [dataAvailability], completion: @escaping ()->Void) {
        var count = 0
        for data in dataInput {
            count += data.dataValue.count
        }
        
        if count != healthDataTypes.count {
            return
        }
        for i in 0..<dataInput.count {
            dataInput[i].dataValue.sort {
                (first, second) in
                print(first.identifier)
                print(second.identifier)
                print()
                return getDataTypeName(for: first.identifier) ?? "" < getDataTypeName(for: second.identifier) ?? ""}
        }
        completion()
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
            print("Selected: \(getDataTypeName(for: dataType)!)")
        }
    }
    

}

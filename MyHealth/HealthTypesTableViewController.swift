//
//  HealthTypesTableViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 9/29/23.
//

import UIKit
import HealthKit

struct dataAvailability {
    let displayName: String
    var dataTypes: [HKSampleType] = []
    var dataValue: [HealthDataValue] = []
}

class HealthTypesTableViewController: UITableViewController {
    
    let healthStore = HealthData.healthStore
    let healthDataTypes: [HKSampleType] = HealthData.readDataTypes
    var dataTypeAvailability: [dataAvailability] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        dataTypeAvailability = [dataAvailability(displayName: "Today"), dataAvailability(displayName: "Last 7 Days"), dataAvailability(displayName: "Last 30 Days"), dataAvailability(displayName: "Older"),dataAvailability(displayName: "No Data Available")]
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        let read = Set(healthDataTypes)
        let share = Set(healthDataTypes)
        HealthData.requestHealthDataAccessIfNeeded(toShare: share, read: read) { success in
            if success {
                self.checkDataAvailability(dataTypesToCheck: self.healthDataTypes)
            }
        }
        
    }
    
    
    func checkDataAvailability(dataTypesToCheck: [HKSampleType]) {
        clearDataTypes()
        for dataType in dataTypesToCheck {
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
                        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: option) { (query, result, error) in
                            if let result = result, 
                                let quantity = getStatisticsQuantity(for: result, with: option),
                                let unit = preferredUnit(for: dataType.identifier) {
                                let value = quantity.doubleValue(for: unit)
                                
                                var index = 0
                                if result.startDate.isToday {
                                    index = 0
                                } else if result.startDate.isWithinLast7Days! {
                                    index = 1
                                } else if result.startDate.isWithinLast30Days! {
                                    index = 2
                                } else {
                                    index = 3
                                }
                                self.dataTypeAvailability[index].dataTypes.append(dataType)
                                self.dataTypeAvailability[index].dataValue.append(HealthDataValue(startDate: result.startDate, endDate: result.endDate, value: value))
                                
                                print("\(dataType.identifier) has data.")
                                print(value)
                                
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            } else if let error = error {
                                // Handle any errors that occurred during the query.
                                print("Error fetching heart rate data: \(error.localizedDescription)")
                            }
                        }
                        
                        self.healthStore.execute(query)
                        
                        
                    } else {
                        print("\(dataType.identifier) has no data.")
                        self.dataTypeAvailability[4].dataTypes.append(dataType)
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
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
        return dataTypeAvailability[section].dataTypes.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if dataTypeAvailability[section].dataTypes.isEmpty {
            return nil
        }
        let header = dataTypeAvailability[section].displayName
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        
        let label = UILabel()
        label.frame = CGRect.init(x: 5, y: 5, width: headerView.frame.width-10, height: headerView.frame.height-10)
        label.text = header
        label.font = .systemFont(ofSize: 25)
        label.textColor = .lightGray
        label.center = headerView.center
        
        headerView.addSubview(label)
        headerView.backgroundColor = tableView.backgroundColor
        
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataTypeAvailability[section].dataTypes.isEmpty {
            return 0
        }
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HealthTypeCell", for: indexPath) as! HealthTypeTableViewCell
            let datasource = dataTypeAvailability[indexPath.section].dataTypes
            let dataType = (datasource[indexPath.row] as HKSampleType).identifier
            // Configure the cell...
            cell.txtTitle?.text = getDataTypeName(for: dataType)
            cell.imgIcon.image = UIImage(systemName: getDataTypeIcon(for: dataType)!)
            cell.backgroundColor = tableView.backgroundColor
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DataAvailableHealthTypeCell", for: indexPath) as! AvailableDataTypeTableViewCell
            let datasource = dataTypeAvailability[indexPath.section]
            let dataType = (datasource.dataTypes[indexPath.row] as HKSampleType).identifier
            let dataValue = (datasource.dataValue[indexPath.row] as HealthDataValue)
            
            let dateformatter = DateFormatter()
            if indexPath.section == 0 {
                dateformatter.dateFormat = "hh:mm"
            } else {
                dateformatter.dateFormat = "dd/MM/yyyy"
            }
            // Configure the cell...
            cell.txtLabel?.text = getDataTypeName(for: dataType)
            cell.imgIcon.image = UIImage(systemName: getDataTypeIcon(for: dataType)!)
            cell.txtData?.text = "\(String(format: "%.1f", dataValue.value)) \(getUnit(for: dataType)!)"
            cell.txtDate?.text = dateformatter.string(from: dataValue.startDate)
            
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
            dataTypeAvailability[i].dataTypes.removeAll()
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "ShowHealthDataSegue") {
            let healthDisplayController = segue.destination as? HealthDisplayViewController
            let selectedCell = self.tableView.indexPath(for: sender as! UITableViewCell)
            let datasource: [HKSampleType] = self.dataTypeAvailability[selectedCell!.section].dataTypes
            let selectedRow = selectedCell?.row
            let dataType = datasource[selectedRow!].identifier
            healthDisplayController?.dataTypeIdentifier = dataType
            print("Selected: \(getDataTypeName(for: dataType)!)")
        }
    }
    

}

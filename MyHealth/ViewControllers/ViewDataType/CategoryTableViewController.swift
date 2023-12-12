//
//  CategoryTableViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 11/30/23.
//

import UIKit
import HealthKit

struct categoryDataAvalability{
    let displayName: String
    var dataValue: [categoryDataValue] = []
}

class CategoryTableViewController: UITableViewController {
    
    let healthStore = HealthData.healthStore
    var healthDataTypes: [HKSampleType] = []
    var currentTitle: String = ""
    var dataAvailability: [categoryDataAvalability] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        dataAvailability = [categoryDataAvalability(displayName: "Today"), categoryDataAvalability(displayName: "Last 7 Days"), categoryDataAvalability(displayName: "Last 30 Days"), categoryDataAvalability(displayName: "Older"), categoryDataAvalability(displayName: "No Data Available")]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let read = Set(healthDataTypes)
        let share = Set(healthDataTypes)
        
        HealthData.requestHealthDataAccessIfNeeded(toShare: share, read: read) {success in 
            if success {
                self.checkDataAvailability(dataTypesToCheck: self.healthDataTypes)
            }
        }
         tableView.reloadData()
    }
    
    func checkDataAvailability(dataTypesToCheck: [HKSampleType]) {
        clearDataTypes()
        for dataType in dataTypesToCheck {
            let datePredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
            
            let query = HKSampleQuery(sampleType: dataType, predicate: datePredicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { (query, results, error) in
                if let error = error {
                    print("Error fetching data for \(dataType): \(error.localizedDescription)")
                } else {
                    if let result = results?.first as? HKCategorySample {
                        let dataValue = categoryDataValue(identifier: dataType.identifier, startDate: result.startDate, endDate: result.endDate, value: result.value)
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
                            self.insertToDataTypes(dataValue: dataValue, at: index)
                            self.tableView.reloadData()
                        }
                    } else {
                        DispatchQueue.main.async {
                            let emptyDataValue = categoryDataValue(identifier: dataType.identifier, startDate: Date(), endDate: Date(), value: 0)
                            self.insertToDataTypes(dataValue: emptyDataValue, at: 4)
                            self.tableView.reloadData()
                        }
                    }
                    
                }
                
            }
            
            healthStore.execute(query)
        }
    }
    
    func insertToDataTypes(dataValue: categoryDataValue, at index: Int) {
        let i = self.dataAvailability[index].dataValue.lastIndex(where: {getDataTypeName(for: $0.identifier) ?? "" < getDataTypeName(for: dataValue.identifier) ?? ""}) ?? -1
        self.dataAvailability[index].dataValue.insert(dataValue, at: i+1)
    }
    
    func clearDataTypes() {
        for i in 0..<dataAvailability.count {
            dataAvailability[i].dataValue.removeAll()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataAvailability[section].dataValue.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if dataAvailability[section].dataValue.isEmpty {
            return nil
        } else {
            let header = dataAvailability[section].displayName
            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
            let label = UILabel()
            label.frame = CGRect(x: 5, y: 5, width: headerView.frame.width-10, height: headerView.frame.height-10)
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
        if dataAvailability[section].dataValue.isEmpty {
            return 0.1
        } else {
            return 50.1
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 4 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryEmptyCell", for: indexPath)
            
            // Configure the cell...
            let datasource = dataAvailability[indexPath.section].dataValue
            let identifier = datasource[indexPath.row].identifier
            cell.textLabel?.text = getDataTypeName(for: identifier)
            cell.imageView?.image = UIImage(systemName: getDataTypeIcon(for: identifier)!)
            cell.tintColor = getDataTypeColor(for: identifier)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryDataCell", for: indexPath) as! CategoryDataTableViewCell
            let datasource = dataAvailability[indexPath.section]
            let dataValue = datasource.dataValue[indexPath.row]
            let identifier = dataValue.identifier
            
            cell.imgIcon.image = UIImage(systemName: getDataTypeIcon(for: identifier)!)
            cell.imgIcon.tintColor = getDataTypeColor(for: identifier)
            cell.txtName.text = getDataTypeName(for: identifier)
            cell.txtName.textColor = getDataTypeColor(for: identifier)
            cell.txtData.text = getCategoryValues(for: identifier)[dataValue.value]
            cell.txtTime.text = dataValue.endDate.toString
            
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowCategoryDataSegue" {
            let categoryDisplayController = segue.destination as? CategoryDisplayViewController
            let selectedRow = tableView.indexPath(for: sender as! UITableViewCell)?.row
            let selectedCategory = healthDataTypes[selectedRow!].identifier
            categoryDisplayController?.dataTypeIdentifier = selectedCategory
        }
     }
    

}

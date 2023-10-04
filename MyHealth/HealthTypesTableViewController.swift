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
}

class HealthTypesTableViewController: UITableViewController {
    
    let healthStore = HealthData.healthStore
    let healthDataTypes: [HKSampleType] = HealthData.readDataTypes
    var dataTypeAvailability: [dataAvailability] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        dataTypeAvailability = [dataAvailability(displayName: "Data Available"), dataAvailability(displayName: "No Data Available")]
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
            let query = HKSampleQuery(sampleType: dataType, predicate: datePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
                if let error = error {
                    print("Error fetching data for \(dataType): \(error.localizedDescription)")
                } else {
                    if let results = results, !results.isEmpty {
                        print("\(dataType.identifier) has data.")
                        self.dataTypeAvailability[0].dataTypes.append(dataType)
                    } else {
                        print("\(dataType.identifier) has no data.")
                        self.dataTypeAvailability[1].dataTypes.append(dataType)
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
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
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataTypeAvailability[section].dataTypes.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HealthTypeCell", for: indexPath) as! HealthTypeTableViewCell
        let datasource = dataTypeAvailability[indexPath.section].dataTypes
        let dataType = (datasource[indexPath.row] as HKSampleType).identifier
        // Configure the cell...
        cell.txtTitle?.text = getDataTypeName(for: dataType)
        cell.imgIcon.image = UIImage(systemName: getDataTypeIcon(for: dataType)!)
        if indexPath.section == 1{
            cell.isUserInteractionEnabled = false
            cell.backgroundColor = tableView.backgroundColor
            cell.accessoryType = .none
        } else {
            cell.isUserInteractionEnabled = true
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.accessoryType = .disclosureIndicator
        }
        return cell
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

//
//  SelectTypesTableViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 1/23/24.
//

import UIKit
import HealthKit

protocol selectedTypeDelegate: AnyObject {
    func receivedTypes( _ types: Set<HKSampleType>)
}

class SelectTypesTableViewController: UITableViewController {
    
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
    
    weak var delegate: selectedTypeDelegate?
    var visitedTypes = Set<HKSampleType>()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        dismiss(animated: true, completion: {
            self.delegate?.receivedTypes(self.visitedTypes)
        })
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return allData.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectTypesCell", for: indexPath)

        let identifier = allData[indexPath.row].identifier
        cell.textLabel?.text = getDataTypeName(for: identifier)
        cell.imageView?.image = UIImage(systemName: getDataTypeIcon(for: identifier)!)
        cell.imageView?.tintColor = getDataTypeColor(for: identifier)
        
        if visitedTypes.contains(allData[indexPath.row]) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let type = allData[indexPath.row]
        if visitedTypes.contains(type) {
            visitedTypes.remove(type)
        } else {
            visitedTypes.insert(type)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

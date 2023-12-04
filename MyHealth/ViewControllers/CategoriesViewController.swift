//
//  CategoriesViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 11/2/23.
//

import UIKit
import HealthKit

class CategoriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let quantityHealth = ViewModels.quantitiesHealth
    let categoryHealth = ViewModels.categoriesHealth
    let group = DispatchGroup()
    var backgroundTask: DispatchWorkItem?
    var healthDataType: [HKSampleType] = []
    var isSearched: Bool = false
    var searchHeader: String {
        if healthDataType.isEmpty {
            return "No Matches"
        } else {
            return "Search Results"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        tableView.reloadData()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if isSearched {
            return 1
        } else {
            return 2
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if !isSearched {
            if section == 0 {
                return quantityHealth.count
            } else {
                return categoryHealth.count
            }
            
        } else {
            return healthDataType.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var header : String
        if !isSearched {
            if section == 0 {
                header = "Quantity Health"
            } else {
                header = "Category Health"
            }
        } else {
            header = searchHeader
        }
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
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if !isSearched {
            if indexPath.section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "QuantityHealthCell", for: indexPath)
                cell.textLabel?.text = quantityHealth[indexPath.row].categoryName
                cell.imageView?.image = UIImage(systemName: quantityHealth[indexPath.row].icon)
                cell.tintColor = quantityHealth[indexPath.row].color
                // Configure the cell...
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryHealthCell", for: indexPath)
                cell.textLabel?.text = categoryHealth[indexPath.row].categoryName
                cell.imageView?.image = UIImage(systemName: categoryHealth[indexPath.row].icon)
                cell.tintColor = quantityHealth[indexPath.row].color
                
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DataTypeCell", for: indexPath)
            let identifier = healthDataType[indexPath.row].identifier
            cell.textLabel?.text = getDataTypeName(for: identifier)
            cell.imageView?.image = UIImage(systemName: getDataTypeIcon(for: identifier)!)
            cell.tintColor = getDataTypeColor(for: identifier)
            return cell
        }
    }
    
    // MARK: - Search Bar Config
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        cancelBackgroundTask()
        performBackgroundTask(searchText: searchText) {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    //MARK: -Background Thread Control
    func performBackgroundTask(searchText: String, completion: @escaping () -> Void) {
        backgroundTask = DispatchWorkItem {
            guard !self.backgroundTask!.isCancelled else {
                self.group.leave()
                return
            }
            
            if searchText == "" {
                self.isSearched = false
            } else {
                self.healthDataType.removeAll()
                for category in ViewModels.quantitiesHealth {
                    for type in category.dataTypes {
                        if ((getDataTypeName(for: type.identifier)?.lowercased().contains(searchText.lowercased())) ?? false){
                            self.healthDataType.append(type)
                        }
                    }
                }
                
                var uniqueType: Set<String> = Set()
                var i = 0
                while uniqueType.count < self.healthDataType.count {
                    let identifier = self.healthDataType[i].identifier
                    if let name = getDataTypeName(for: identifier),
                       uniqueType.contains(name) || identifier == HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue {
                        self.healthDataType.remove(at: i)
                    } else {
                        i+=1
                        uniqueType.insert(getDataTypeName(for: identifier)!)
                    }
                }
                self.isSearched = true
            }
            
            if !self.backgroundTask!.isCancelled {
                completion()
            }
            
            self.group.leave()
        }
        
        group.enter()
        DispatchQueue.global(qos: .background).async(execute: backgroundTask!)
    }
    
    func cancelBackgroundTask() {
        backgroundTask?.cancel()
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        view.endEditing(true)
        if segue.identifier == "ShowHealthTypesSegue" {
            let healthDataController = segue.destination as? HealthTypesTableViewController
            let selectedRow = self.tableView.indexPath(for: sender as! UITableViewCell)?.row
            let selectedCategory = quantityHealth[selectedRow!] as HealthCategory
            healthDataController?.healthDataTypes = selectedCategory.dataTypes
            healthDataController?.currentTitle = selectedCategory.categoryName
            healthDataController?.isFavView = false
        }
        
        if segue.identifier == "ShowDataSegue" {
            let healthDisplayController = segue.destination as? HealthDisplayViewController
            let selectedRow = self.tableView.indexPath(for: sender as! UITableViewCell)?.row
            healthDisplayController?.dataTypeIdentifier = healthDataType[selectedRow!].identifier
            
        }
        
        if segue.identifier == "ShowCategoryTypeSegue" {
            let categoryTableController = segue.destination as? CategoryTableViewController
            let selectedRow = self.tableView.indexPath(for: sender as! UITableViewCell)?.row
            let selectedCategory = categoryHealth[selectedRow!] as HealthCategory
            categoryTableController?.healthDataTypes = selectedCategory.dataTypes
            categoryTableController?.currentTitle = selectedCategory.categoryName
        }
    }
    

}

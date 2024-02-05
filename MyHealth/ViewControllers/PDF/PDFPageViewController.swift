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
    var start: Date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date())!)
    var end: Date = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
    
    let reportTypes: [PDFOption] = [
        PDFOption(title: "Report Favorite Health Types", segue: "PDFPreviewSegue"),
        PDFOption(title: "Report Selected Health Types", segue: "SelectDataTypeSegue"),
        PDFOption(title: "Report Based on Category", segue: "SelectCategorySegue")
    ]
    
    var selectedTypes = Set<HKSampleType>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        dpkStart.date = start
        dpkEnd.date = end
        dpkStart.maximumDate = dpkEnd.date
        dpkStart.minimumDate = Calendar.current.date(byAdding: .month, value: -1, to: end)
        
    }
    
    @IBAction func dpkEndChange(_ sender: UIDatePicker) {
        end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: sender.date)!
        dpkStart.maximumDate = end
        dpkStart.minimumDate = Calendar.current.date(byAdding: .month, value: -1, to: end)
    }
    
    @IBAction func dpkStartChange(_ sender: UIDatePicker) {
        start = Calendar.current.startOfDay(for: sender.date)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "PDFPreviewSegue":
            let previewVC = segue.destination as? PDFPreviewViewController
            previewVC?.dataList = selectedTypes
            previewVC?.startDate = start
            previewVC?.endDate = end
        case "SelectDataTypeSegue":
            let selectTypeVC = (segue.destination as? UINavigationController)?.children.first as? SelectTypesTableViewController
            selectTypeVC?.delegate = self
        case "SelectCategorySegue":
            let selectCategoryVC = (segue.destination as? UINavigationController)?.children.first as? SelectCategoryTableViewController
            selectCategoryVC?.delegate = self
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
        return reportTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportOptionCell", for: indexPath)
        cell.textLabel?.text = reportTypes[indexPath.row].title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            var types: [HKSampleType] {
                var res: [HKSampleType] = []
                for type in ViewModels.favDataType {
                    if type is HKQuantityType {
                        res.append(type)
                    }
                }
                
                return res
            }
            selectedTypes = Set<HKSampleType>(types)
        }
        
        performSegue(withIdentifier: reportTypes[indexPath.row].segue, sender: self)
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

//
//  CategoryDisplayViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 11/30/23.
//

import UIKit
import HealthKit
import SwiftUI

class CategoryDisplayViewController: UIViewController {
    
    @IBOutlet weak var dpkStart: UIDatePicker!
    @IBOutlet weak var dpkEnd: UIDatePicker!
    @IBOutlet weak var chartView: UIView!
    
    let healthStore = HealthData.healthStore
    var dataValues: [categoryDataValue] = []
    var dataTypeIdentifier: String = ""
    var start: Date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date())!)
    var end: Date = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    func showData() {
        let sampleType = getSampleType(for: dataTypeIdentifier)
        if sampleType is HKCategoryType {
            let readType = Set([sampleType!])
            let shareType = Set([sampleType!])
            HealthData.requestHealthDataAccessIfNeeded(toShare: shareType, read: readType) {success in 
                if success {
                    self.categoryQuery(for: sampleType!) {results in 
                        DispatchQueue.main.async {
                            self.dataValues = results
                            self.chartView.subviews.forEach({
                                $0.removeFromSuperview()
                            })
                            let categoryChart = CategoryDataChart(data: self.dataValues, identifier: self.dataTypeIdentifier, startTime: self.start, endTime: self.end)
                            let categoryChartController = UIHostingController(rootView: categoryChart)
                            categoryChartController.view.translatesAutoresizingMaskIntoConstraints = false
                            categoryChartController.view.isUserInteractionEnabled = true
                            self.addChild(categoryChartController)
                            self.chartView.addSubview(categoryChartController.view)
                            self.view.addConstraint(categoryChartController.view.centerXAnchor.constraint(equalTo: self.chartView.centerXAnchor))
                            self.view.addConstraint(categoryChartController.view.centerYAnchor.constraint(equalTo: self.chartView.centerYAnchor))
                        }
                    }
                }
            }
        }
    }
    
    func categoryQuery(for sampleType: HKSampleType, completion: @escaping (_ results: [categoryDataValue]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { query,result,error in
            if let error = error {
                print("Error fetching data for \(sampleType.identifier): \(error.localizedDescription)")
            } else {
                if let result = result as? [HKCategorySample] {
                    var dataValues = result.compactMap({categoryDataValue(identifier: self.dataTypeIdentifier, startDate: $0.startDate, endDate: $0.endDate, value: $0.value)})
                    
                    completion(dataValues)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    @IBAction func startDateChange(_ sender: UIDatePicker) {
        start = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: sender.date)!
        dpkEnd.minimumDate = sender.date
        presentedViewController?.dismiss(animated: true)
    }
    
    @IBAction func endDateChange(_ sender: UIDatePicker) {
        end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: sender.date)!
        dpkStart.maximumDate = sender.date
        presentedViewController?.dismiss(animated: true)
    }
    
    @IBAction func clickedShow(_ sender: Any) {
        showData()
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

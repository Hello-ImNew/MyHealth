//
//  SleepChartViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 11/7/23.
//

import UIKit
import HealthKit
import SwiftUI

class SleepChartViewController: UIViewController {

    @IBOutlet weak var chartView: UIView!
    let dataType = HKCategoryType(.sleepAnalysis)
    let healthStore = HealthData.healthStore
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let current = Calendar.current
        
        guard let lastWeek = current.date(byAdding: .day, value: -7, to: Date()),
              let start = current.date(bySettingHour: 18, minute: 00, second: 0, of: lastWeek),
              let end = current.date(bySettingHour: 18, minute: 00, second: 0, of: Date())
        else {
            fatalError("Cannot Get Last Week Date")
        }
        showData(from: start, to: end)
    }
    
    func showData(from start: Date, to end: Date) {
        let readType = Set([dataType])
        let shareType = Set([dataType])
        
        HealthData.requestHealthDataAccessIfNeeded(toShare: shareType, read: readType) {success in 
            if !success {
                return
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictEndDate)
            
            let query = HKSampleQuery(sampleType: self.dataType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, result, error) in
                if let error = error {
                    print("Error fetching data for \(self.dataType): \(error.localizedDescription)")
                } else {
                    if let result = result as? [HKCategorySample] {
                        DispatchQueue.main.async {
                            for r in result {
                                print(r.value)
                            }
                            let chart = SleepChart(data: result)
                            self.chartView.subviews.forEach({
                                $0.removeFromSuperview()
                            })
                            let chartController = UIHostingController(rootView: chart)
                            chartController.view.translatesAutoresizingMaskIntoConstraints = false
                            self.addChild(chartController)
                            self.chartView.addSubview(chartController.view)
//                            self.view.addConstraint(chartController.view.centerXAnchor.constraint(equalTo: self.chartView.centerXAnchor))
//                            self.view.addConstraint(chartController.view.centerYAnchor.constraint(equalTo: self.chartView.centerYAnchor))
                            NSLayoutConstraint.activate([
                                chartController.view.topAnchor.constraint(equalTo: self.chartView.topAnchor),
                                chartController.view.leadingAnchor.constraint(equalTo: self.chartView.leadingAnchor),
                                chartController.view.trailingAnchor.constraint(equalTo: self.chartView.trailingAnchor),
                                chartController.view.bottomAnchor.constraint(equalTo: self.chartView.bottomAnchor),
                            ])
                            chartController.didMove(toParent: self)
                        }
                    }
                }
            }
            
            
            self.healthStore.execute(query)
        }
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

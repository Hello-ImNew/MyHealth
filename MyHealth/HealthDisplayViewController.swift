//
//  HealthDisplayViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 9/22/23.
//

import UIKit
import SwiftUI
import Foundation
import HealthKit

class HealthDisplayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    
    @IBOutlet weak var startDate: UIDatePicker!
    @IBOutlet weak var endDate: UIDatePicker!
    @IBOutlet weak var healthTableView: UITableView!
    @IBOutlet weak var settingView: UIStackView!
    @IBOutlet weak var btnShowChart: UIButton!
    @IBOutlet weak var viewTableOrChart: UIView!
    
    
    let healthStore = HealthData.healthStore
    var dataTypeIdentifier: String = ""
    var dataValues: [HealthDataValue] = []
    var start : Date = Calendar.current.date(bySettingHour: 2, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)!
    var end : Date = Date()
    var isCollapsed: Bool = false
    var settingViewHeight : Double = 0
    var isChartShow = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        healthTableView.delegate = self
        healthTableView.dataSource = self
        reloadTable("Adjust setting to show your health data.")
        startDate.date = start
        startDate.maximumDate = endDate.date
        endDate.minimumDate = startDate.date
        settingViewHeight = settingView.bounds.size.height
        print("current Identifier \(dataTypeIdentifier)")
        
        let settingButton: UIBarButtonItem = UIBarButtonItem(title: "Setting", style: .plain, target: self, action: #selector(animateView))
        
        self.navigationItem.rightBarButtonItem = settingButton
        self.view.backgroundColor = healthTableView.backgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showData()
    }
    
    @IBAction func startDate(_ sender: Any) {
        start = Calendar.current.date(bySettingHour: 2, minute: 0, second: 0, of: startDate.date)!
        endDate.isEnabled = true
        endDate.minimumDate = startDate.date
        presentedViewController?.dismiss(animated: true)
    }
    
    
    @IBAction func endDate(_ sender: Any) {
        end = endDate.date
        startDate.maximumDate = endDate.date
        presentedViewController?.dismiss(animated: true)
    }
    
    @IBAction func clickedShow(_ sender: Any) {
        showData()
    }
    
    func showData() {
        isCollapsed = false
        let sampleType = getSampleType(for: dataTypeIdentifier)
        if sampleType is HKQuantityType {
            let shareType = Set([sampleType!])
            let readType = Set([sampleType!])
            HealthData.requestHealthDataAccessIfNeeded(toShare: shareType, read: readType) { success in
                if success {
                    self.performQuery {
                        DispatchQueue.main.async {
                            self.reloadTable()
                            self.animateView()
                        }
                    }
                } else {
                    print("oops")
                }
            }
        }
    }
    
    func performQuery(_ completion: @escaping () -> Void) {
        let quantityType = HKQuantityType(HKQuantityTypeIdentifier(rawValue: dataTypeIdentifier))
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let options = getStatisticsOptions(for: dataTypeIdentifier)
        let anchorDate = createAnchorDate(for: start)
        let dailyInterval = DateComponents(day: 1)
        
        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options, anchorDate: anchorDate, intervalComponents: dailyInterval)
        
        let updateInterfaceWithStaticstics: (HKStatisticsCollection) -> Void = {statisticsCollection in
            self.dataValues = []
            
            let startDate = self.start
            let endDate = self.end
            
            statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { [weak self] (statistics, stop) in
                var dataValue = HealthDataValue(startDate: statistics.startDate, endDate: statistics.endDate, value: 0)
                if let quantity = getStatisticsQuantity(for: statistics, with: options),
                   let identifier = self?.dataTypeIdentifier,
                   let unit = preferredUnit(for: identifier) {
                    dataValue.value = quantity.doubleValue(for: unit)
                }
                
                self?.dataValues.append(dataValue)
            }
            
            completion()
        }
        
        
        query.initialResultsHandler = { query, statisticsCollection, error in
            if let statisticsCollection = statisticsCollection {
                updateInterfaceWithStaticstics(statisticsCollection)
            }
        }
        
        self.healthStore.execute(query)
    }
    
    @objc func animateView() {
        isCollapsed = !isCollapsed
        UIView.animate(withDuration: 1, animations: {
            if self.isCollapsed {
                self.settingView.alpha = 0
            } else {
                self.settingView.alpha = 1
            }
            self.settingView.isHidden = self.isCollapsed
        })
    }
    
    @IBAction func clickedShowChart(_ sender: Any) {
        if dataValues.count == 0 {
            return
        }
        toggleView()
    }
    
    func toggleView() {
        isChartShow = !isChartShow
        if isChartShow {
            addChart()
            btnShowChart.setTitle("Show Table", for: .normal)
        } else {
            btnShowChart.setTitle("Show Chart", for: .normal)
            addTable()
        }
    }
    
    func addChart() {
        viewTableOrChart.subviews.forEach({
            if !($0 is UITableView) {
                $0.removeFromSuperview()
            } else {
                $0.isHidden = true
            }
        })
        let chartView = HealthChartView(data: dataValues)
        let chartUIView = UIHostingController(rootView: chartView)
        chartUIView.view.translatesAutoresizingMaskIntoConstraints = false
        viewTableOrChart.addSubview(chartUIView.view)
        
        NSLayoutConstraint.activate([
            chartUIView.view.centerXAnchor.constraint(equalTo: self.viewTableOrChart.centerXAnchor),
            chartUIView.view.centerYAnchor.constraint(equalTo: self.viewTableOrChart.centerYAnchor)
        ])
        chartUIView.didMove(toParent: self)
    }
    
    func addTable() {
        viewTableOrChart.subviews.forEach({
            if !($0 is UITableView) {
                $0.removeFromSuperview()
            }
        })
        healthTableView.isHidden = false
    }
    // MARK: - TableView Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HealthDataCell", for: indexPath)
        let value = dataValues[indexPath.row]
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "dd/MM/yyyy"
        
        cell.textLabel?.text = String(format: "%.0f \(getUnit(for: dataTypeIdentifier)!)", value.value)
        cell.detailTextLabel?.text = dateformatter.string(from: value.startDate)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        
        let label = UILabel()
        label.frame = CGRect.init(x: 5, y: 5, width: headerView.frame.width-10, height: headerView.frame.height-10)
        label.text = getDataTypeName(for: dataTypeIdentifier) ?? ""
        label.font = .systemFont(ofSize: 25)
        label.textColor = .lightGray
        label.center = headerView.center
        
        headerView.addSubview(label)
        headerView.backgroundColor = healthTableView.backgroundColor
        
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataValues.isEmpty {
            return 0
        } else {
            return 50
        }
    }
    
    func reloadTable(_ message: String = "No Data"){
        if dataValues.count == 0 {
            setEmptyDataView(message)
        } else {
            healthTableView.backgroundView = nil
        }
        if isChartShow {
            addChart()
        } else {
            addTable()
            healthTableView.reloadData()
        }
    }
    
    func setEmptyDataView(_ message: String) {
        let emptyDataView = EmptyDataBackgroundView(message: message)
        healthTableView.backgroundView = emptyDataView
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



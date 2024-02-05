//
//  CategoryDisplayViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 11/30/23.
//

import UIKit
import HealthKit
import SwiftUI

class CategoryDisplayViewController: UIViewController, AddDataDelegate {
    enum displayMode: Int {
        case chart = 0
        case condenseChart
        case table
    }
    
    @IBOutlet weak var dpkStart: UIDatePicker!
    @IBOutlet weak var dpkEnd: UIDatePicker!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var settingView: UIStackView!
    @IBOutlet weak var addDataBtn: UIButton!
    @IBOutlet weak var condenseChartBtn: UIButton!
    
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    let healthStore = HealthData.healthStore
    var mode: displayMode!
    var isCollapse: Bool = false
    var dataValues: [categoryDataValue] = []
    var dataTypeIdentifier: String = ""
    var start: Date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date())!)
    var end: Date = Date()
    var currentTitle: String {
        if let title = getDataTypeName(for: dataTypeIdentifier) {
            return title
        } else {
            return "Health Data"
        }
    }
    var isFav : Bool {
        return ViewModels.favHealthTypes.contains(dataTypeIdentifier)
    }
    
    var canAdd: Bool {
        get {
            return !addDataBtn.isHidden
        }
        set(value) {
            addDataBtn.isHidden = !value
        }
    }
    
    var chartHeight: Int {
        if settingView.isHidden {
            return Int(chartView.frame.size.height - settingView.frame.size.height)
        } else {
            return Int(chartView.frame.size.height)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canAdd = isAllowedShared(for: dataTypeIdentifier)

        // Do any additional setup after loading the view.
        self.title = currentTitle
        dpkStart.date = start
        dpkEnd.date = end
        dpkStart.maximumDate = dpkEnd.date
        dpkEnd.minimumDate = dpkStart.date
        
        if ViewModels.notificationType.contains(where: {$0 == dataTypeIdentifier}) {
            mode = .table
        } else {
            mode = .chart
        }
        
        if dataTypeIdentifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
            condenseChartBtn.isHidden = false
        } else {
            condenseChartBtn.isHidden = true
        }
        
        let settingButton = UIBarButtonItem(title: "Setting", style: .plain, target: self, action: #selector(settingTapped))
        self.navigationItem.rightBarButtonItem = settingButton
        createFavButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showData()
    }
    
    func showData() {
        let sampleType = getSampleType(for: dataTypeIdentifier)
        if sampleType is HKCategoryType {
            let readType = Set([sampleType!])
            var shareType : Set<HKSampleType>? = nil
            if isAllowedShared(for: dataTypeIdentifier) {
                shareType?.insert(sampleType!)
            }
            HealthData.requestHealthDataAccessIfNeeded(toShare: shareType, read: readType) {success in
                if success {
                    self.categoryQuery(for: sampleType!) {results in 
                        DispatchQueue.main.async {
                            self.animateView(true)
                            self.dataValues = results
                            self.chartView.subviews.forEach({
                                $0.removeFromSuperview()
                            })
                            
                            self.display()
                        }
                    }
                }
            }
        }
    }
    
    func categoryQuery(for sampleType: HKSampleType, completion: @escaping (_ results: [categoryDataValue]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate, .strictEndDate])
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { query,result,error in
            if let error = error {
                print("Error fetching data for \(sampleType.identifier): \(error.localizedDescription)")
            } else {
                if let result = result as? [HKCategorySample] {
                    let dataValues = result.compactMap({categoryDataValue(identifier: self.dataTypeIdentifier, startDate: $0.startDate, endDate: $0.endDate, value: $0.value)})
                    
                    completion(dataValues)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    func display() {
        chartView.subviews.forEach({
            $0.removeFromSuperview()
        })
        
        switch mode {
        case .chart:
            if ViewModels.categoryValueType.contains(where: {$0 == self.dataTypeIdentifier}) {
                self.addCategorySingleValueChart()
            } else {
                self.addCategoryChart()
            }
        case .condenseChart:
            addCondenseChart()
        case .table:
            setupTableView()
        default:
            return
        }
    }
    
    func animateView(_ collapse: Bool) {
        isCollapse = collapse
        UIView.animate(withDuration: 1, animations: {
            if self.isCollapse {
                self.settingView.alpha = 0
            } else {
                self.settingView.alpha = 1
            }
            
            self.settingView.isHidden = self.isCollapse
        })
    }
    
    func createFavButton() {
        var imageName : String
        if isFav {
            imageName = "star.fill"
        } else {
            imageName = "star"
        }
        let image = UIImage(systemName: imageName)
        let button = UIButton(type: .custom) as UIButton
        button.setImage(image, for: .normal)
        button.tintColor = UIColor.systemYellow
        button.imageView?.contentMode = .scaleToFill
        
        chartView.addSubview(button)
        let buttonSize = CGSize(width: 40, height: 40)
        let parentFrame = chartView.frame
        let buttonX = parentFrame.width - buttonSize.width
        let buttonY = parentFrame.height - buttonSize.height
        
        button.frame = CGRect(x: buttonX, y: buttonY, width: buttonSize.width, height: buttonSize.height)
        button.removeFromSuperview()
        
        button.addTarget(self, action: #selector(clickedFavButton(_:)), for: .touchUpInside)
        view.addSubview(button)
        
        //constraints
        button.bottomAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 0).isActive = true
        button.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: 0).isActive = true
        button.widthAnchor.constraint(equalToConstant: buttonSize.width).isActive = true
        button.heightAnchor.constraint(equalToConstant: buttonSize.height).isActive = true
        button.imageView?.widthAnchor.constraint(equalToConstant: buttonSize.width).isActive = true
        button.imageView?.heightAnchor.constraint(equalToConstant: buttonSize.height).isActive = true
        button.imageView?.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    func addCategoryChart() {
        let categoryChart = CategoryDataChart(data: self.dataValues, identifier: self.dataTypeIdentifier, startTime: self.start, endTime: self.end)
        let categoryChartController = UIHostingController(rootView: categoryChart)
        categoryChartController.view.translatesAutoresizingMaskIntoConstraints = false
        categoryChartController.view.isUserInteractionEnabled = true
        self.addChild(categoryChartController)
        self.chartView.addSubview(categoryChartController.view)
        
        NSLayoutConstraint.activate([
            categoryChartController.view.topAnchor.constraint(equalTo: self.chartView.topAnchor),
            categoryChartController.view.leadingAnchor.constraint(equalTo: self.chartView.leadingAnchor),
            categoryChartController.view.trailingAnchor.constraint(equalTo: self.chartView.trailingAnchor),
            categoryChartController.view.bottomAnchor.constraint(equalTo: self.chartView.bottomAnchor),
        ])
    }
    
    func addCategorySingleValueChart() {
        let categoryChart = CategorySingleValueChart(data: self.dataValues, identifier: self.dataTypeIdentifier, startTime: self.start, endTime: self.end)
        let categoryChartController = UIHostingController(rootView: categoryChart)
        categoryChartController.view.translatesAutoresizingMaskIntoConstraints = false
        categoryChartController.view.isUserInteractionEnabled = true
        self.addChild(categoryChartController)
        self.chartView.addSubview(categoryChartController.view)
        
        NSLayoutConstraint.activate([
            categoryChartController.view.topAnchor.constraint(equalTo: self.chartView.topAnchor),
            categoryChartController.view.leadingAnchor.constraint(equalTo: self.chartView.leadingAnchor),
            categoryChartController.view.trailingAnchor.constraint(equalTo: self.chartView.trailingAnchor),
            categoryChartController.view.bottomAnchor.constraint(equalTo: self.chartView.bottomAnchor),
        ])
    }
    
    func addCondenseChart() {
        let chart = CategoryCondensedChart(data: dataValues, identifier: dataTypeIdentifier, startTime: start, endTime: end)
        let chartController = UIHostingController(rootView: chart)
        chartController.view.translatesAutoresizingMaskIntoConstraints = false
        chartController.view.isUserInteractionEnabled = true
        self.addChild(chartController)
        self.chartView.addSubview(chartController.view)
        
        NSLayoutConstraint.activate([
            chartController.view.topAnchor.constraint(equalTo: chartView.topAnchor),
            chartController.view.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            chartController.view.trailingAnchor.constraint(equalTo: chartView.trailingAnchor),
            chartController.view.bottomAnchor.constraint(equalTo: chartView.bottomAnchor)
        ])
    }
    
    @objc func settingTapped() {
        animateView(!isCollapse)
    }
    
    @objc func clickedFavButton(_ sender: UIButton) {
        var imageName : String
        if isFav {
            imageName = "star"
            ViewModels.removeFavHealthType(for: dataTypeIdentifier)
        } else {
            imageName = "star.fill"
            ViewModels.addFavHealthType(for: dataTypeIdentifier)
        }
        let image = UIImage(systemName: imageName)
        sender.setImage(image, for: .normal)
        print(ViewModels.favHealthTypes)
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
    
    @IBAction func showCondenseChart(_ sender: Any) {
        if mode == .chart {
            mode = .condenseChart
        } else {
            mode = .chart
        }
        display()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "AddCategoryDataSegue" {
            if let navController = segue.destination as? UINavigationController,
               let addCategoryController = navController.viewControllers.first as? AddCategoryDataViewController {
                addCategoryController.identifier = dataTypeIdentifier
                addCategoryController.delegate = self
            }
            
        }
    }
}

extension CategoryDisplayViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if dataValues.isEmpty {
            return 1
        }
        return dataValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell") ??
        UITableViewCell(style: .default, reuseIdentifier: "NotificationCell")
        if dataValues.isEmpty {
            cell.textLabel?.text = "No data"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, yyyy hh:mm"
            cell.textLabel?.text = formatter.string(from: dataValues[indexPath.row].startDate)
        }
        return cell
    }
    
    func setupTableView() {
        
        
        chartView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: chartView.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: chartView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: chartView.trailingAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
}

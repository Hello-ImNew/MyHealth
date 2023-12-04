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

class HealthDisplayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddDataDelegate {
    
    
    
    @IBOutlet weak var startDate: UIDatePicker!
    @IBOutlet weak var endDate: UIDatePicker!
    @IBOutlet weak var healthTableView: UITableView!
    @IBOutlet weak var settingView: UIStackView!
    @IBOutlet weak var btnShowChart: UIButton!
    @IBOutlet weak var viewTableOrChart: UIView!
    @IBOutlet weak var btnAddData: UIButton!
    
    
    let healthStore = HealthData.healthStore
    var dataTypeIdentifier: String = ""
    var dataValues: [quantityDataValue] = []
    var start : Date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: Date())!)
    var end : Date = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
    var isCollapsed: Bool = false
    var settingViewHeight : Double = 0
    var isChartShow = false
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        healthTableView.delegate = self
        healthTableView.dataSource = self
        self.title = currentTitle
        reloadTable("Adjust setting to show your health data.")
        startDate.date = start
        startDate.maximumDate = endDate.date
        endDate.minimumDate = startDate.date
        settingViewHeight = settingView.bounds.size.height
        
        print("current Identifier \(dataTypeIdentifier)")
        
        let settingButton: UIBarButtonItem = UIBarButtonItem(title: "Setting", style: .plain, target: self, action: #selector(animateView))
        
        self.navigationItem.rightBarButtonItem = settingButton
        self.view.backgroundColor = healthTableView.backgroundColor
        checkAdding()
        createFavButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showData()
    }
    
    func checkAdding() {
        if isAllowedShared(for: dataTypeIdentifier) {
            self.btnAddData.isHidden = false
        } else {
            self.btnAddData.isHidden = true
        }
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

    @IBAction func clinkedAddData(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if dataTypeIdentifier == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue {
            let controller = storyboard.instantiateViewController(withIdentifier: "AddBloodPressureController") as? AddBloodPressureViewController
            let navVC = UINavigationController(rootViewController: controller!)
            controller?.title = getDataTypeName(for: dataTypeIdentifier)
            controller?.delegate = self
            self.showDetailViewController(navVC, sender: self)
            
        } else {
            let controller = storyboard.instantiateViewController(withIdentifier: "AddDataController") as? AddHealthDataViewController
            let navVC = UINavigationController(rootViewController: controller!)
            controller?.title = getDataTypeName(for: dataTypeIdentifier)
            controller?.dataTypeIDentifier = dataTypeIdentifier
            controller?.delegate = self
            self.showDetailViewController(navVC, sender: self)
        }
        
    }
    
    func showData() {
        let sampleType = getSampleType(for: dataTypeIdentifier)
        if sampleType is HKQuantityType {
            var readType = Set([sampleType!])
            var shareType: Set<HKSampleType>? = Set([sampleType!])
            if dataTypeIdentifier == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue {
                let secondSampleType = getSampleType(for: HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue)
                readType.insert(secondSampleType!)
                shareType?.insert(secondSampleType!)
            }
            if !isAllowedShared(for: dataTypeIdentifier) {
                shareType = nil
            }
            HealthData.requestHealthDataAccessIfNeeded(toShare: shareType, read: readType) { success in
                if success {
                    performQuery(for: self.dataTypeIdentifier, from: self.start, to: self.end) { result in
                        DispatchQueue.main.async {
                            self.dataValues = result
                            self.reloadTable()
                            if self.isCollapsed == false {
                                self.animateView()
                            }
                        }
                    }
                } else {
                    print("oops")
                }
            }
        }
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
            self.reloadTable()
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
        let chartView = HealthChartView(dataIdentifier: dataTypeIdentifier, data: dataValues )
        let chartUIView = UIHostingController(rootView: chartView)
        chartUIView.view.translatesAutoresizingMaskIntoConstraints = false
        chartUIView.view.isUserInteractionEnabled = true
        addChild(chartUIView)
        viewTableOrChart.addSubview(chartUIView.view)
        view.addConstraint(chartUIView.view.centerXAnchor.constraint(equalTo: self.viewTableOrChart.centerXAnchor))
        view.addConstraint(chartUIView.view.centerYAnchor.constraint(equalTo: self.viewTableOrChart.centerYAnchor))
        
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
        
        viewTableOrChart.addSubview(button)
        let buttonSize = CGSize(width: 40, height: 40)
        let parentFrame = viewTableOrChart.frame
        let buttonX = parentFrame.width - buttonSize.width
        let buttonY = parentFrame.height - buttonSize.height
        
        button.frame = CGRect(x: buttonX, y: buttonY, width: buttonSize.width, height: buttonSize.height)
        button.removeFromSuperview()
        
        button.addTarget(self, action: #selector(clickedFavButton(_:)), for: .touchUpInside)
        view.addSubview(button)
        
        //constraints
        button.bottomAnchor.constraint(equalTo: viewTableOrChart.bottomAnchor, constant: 0).isActive = true
        button.trailingAnchor.constraint(equalTo: viewTableOrChart.trailingAnchor, constant: 0).isActive = true
        button.widthAnchor.constraint(equalToConstant: buttonSize.width).isActive = true
        button.heightAnchor.constraint(equalToConstant: buttonSize.height).isActive = true
        button.imageView?.widthAnchor.constraint(equalToConstant: buttonSize.width).isActive = true
        button.imageView?.heightAnchor.constraint(equalToConstant: buttonSize.height).isActive = true
        button.imageView?.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        cell.textLabel?.text = "\(value.displayString) \(getUnit(for: dataTypeIdentifier) ?? "")"
        cell.detailTextLabel?.text = dateformatter.string(from: value.startDate)
        return cell
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





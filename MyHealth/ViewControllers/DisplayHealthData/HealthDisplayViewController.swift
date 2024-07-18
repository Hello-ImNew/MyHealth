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
    
    @IBOutlet weak var healthTableView: UITableView!
    @IBOutlet weak var settingView: UIView!
    @IBOutlet weak var btnShowChart: UIButton!
    @IBOutlet weak var viewTableOrChart: UIView!
    @IBOutlet weak var btnAddData: UIButton!
    @IBOutlet weak var rangeBtn: UIButton!
    @IBOutlet weak var dateBtn: UIButton!
    @IBOutlet weak var datePicker: UIPickerView!
    @IBOutlet weak var rangeView: UIView!
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var showDataBtn: UIButton!
    @IBOutlet weak var settingParent: UIStackView!
    @IBOutlet weak var spacerView: UIView!
    @IBOutlet weak var contentView: UIStackView!
    
    
    let healthStore = HealthData.healthStore
    var dataTypeIdentifier: String = ""
    var dataValues: [quantityDataValue] = []
    var isCollapsed: Bool = false
    var isChartShow = false
    
    var selectedRange: rangeOption = .week
    var selectDay: Int = Calendar.current.component(.day, from: Date())
    var selectMonth: Int = Calendar.current.component(.month, from: Date())
    var selectYear: Int = Calendar.current.component(.year, from: Date())
    
    var selectedDay: Date {
        let date = Calendar.current.date(from: DateComponents(year: selectYear, month: selectMonth, day: selectDay))
        
        return date!
    }
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
    
    var start: Date {
        switch selectedRange {
        case .week:
            return Calendar.current.date(byAdding: .day, value: -6, to: selectedDay)!
        case .month:
            return beginOfMonth(year: selectYear, month: selectMonth)
        case .year:
            return beginOfYear(year: selectYear)
        }
    }
    
    var end: Date {
        switch selectedRange {
        case .week:
            return selectedDay
        case .month:
            return endOfMonth(year: selectYear, month: selectMonth)
        case .year:
            return endOfYear(year: selectYear)
        }
    }
    
    var yearOption: [Int] = Array(2015...(Calendar.current.component(.year, from: Date()) + 5))
    var monthOption: [Int] = Array(1...12)
    let rangeOptions: [rangeOption] = [.week, .month, .year]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        healthTableView.delegate = self
        healthTableView.dataSource = self
        datePicker.delegate = self
        datePicker.dataSource = self
        
        self.title = currentTitle
        reloadTable("Adjust setting to show your health data.")
        
        let settingButton: UIBarButtonItem = UIBarButtonItem(title: "Setting", style: .plain, target: self, action: #selector(animateView))
        
        self.navigationItem.rightBarButtonItem = settingButton
        self.view.backgroundColor = healthTableView.backgroundColor
        
        dateBtn.setTitle(selectedDayToString(), for: .normal)
        datePicker.selectRow(yearOption.firstIndex(of: selectYear)!, inComponent: 0, animated: false)
        datePicker.selectRow(monthOption.firstIndex(of: selectMonth)!, inComponent: 1, animated: false)
        datePicker.selectRow(selectDay - 1, inComponent: 2, animated: false)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
        
        rangeView.layer.cornerRadius = 8
        dateView.layer.cornerRadius = 8
        
        checkAdding()
        createFavButton()
        setupRangePicker()
        settingView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settingView.isHidden = true
        showData()
    }
    
    func setupRangePicker() {
        let rangeClosure = { (action: UIAction) in
            switch action.title {
            case self.rangeOptions[0].rawValue:
                self.selectedRange = .week
            case self.rangeOptions[1].rawValue:
                self.selectedRange = .month
            case self.rangeOptions[2].rawValue:
                self.selectedRange = .year
            default:
                return
            }
            
            self.dateBtn.setTitle(self.selectedDayToString(), for: .normal)
            self.datePicker.reloadAllComponents()
            self.datePicker.selectRow(self.yearOption.firstIndex(of: self.selectYear)!, inComponent: 0, animated: false)
            self.datePicker.selectRow(self.monthOption.firstIndex(of: self.selectMonth)!, inComponent: 1, animated: false)
            self.datePicker.selectRow(self.selectDay - 1, inComponent: 2, animated: false)
        }
        
        let options = rangeOptions.map({ element in
            return UIAction(title: element.rawValue, handler: rangeClosure)
        })
        
        options[0].state = .on
        rangeBtn.changesSelectionAsPrimaryAction = true
        rangeBtn.showsMenuAsPrimaryAction = true
        rangeBtn.menu = UIMenu(title: "Choose time range", children: options)
    }
    
    func checkAdding() {
        if isAllowedShared(for: dataTypeIdentifier) {
            self.btnAddData.isHidden = false
        } else {
            self.btnAddData.isHidden = true
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
                    performQuery(for: self.dataTypeIdentifier, from: self.start, to: self.end, range: self.selectedRange) { result in
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
        if selectedRange == .year {
            let chartView = YearlyHealthChartView(dataIdentifier: dataTypeIdentifier, data: dataValues )
            let chartUIView = UIHostingController(rootView: chartView)
            chartUIView.view.translatesAutoresizingMaskIntoConstraints = false
            chartUIView.view.isUserInteractionEnabled = true
            addChild(chartUIView)
            viewTableOrChart.addSubview(chartUIView.view)
            view.addConstraint(chartUIView.view.centerXAnchor.constraint(equalTo: self.viewTableOrChart.centerXAnchor))
            view.addConstraint(chartUIView.view.centerYAnchor.constraint(equalTo: self.viewTableOrChart.centerYAnchor))
            
            chartUIView.didMove(toParent: self)
        } else {
            let chartView = HealthChartView(dataIdentifier: dataTypeIdentifier, data: dataValues, range: selectedRange)
            let chartUIView = UIHostingController(rootView: chartView)
            chartUIView.view.translatesAutoresizingMaskIntoConstraints = false
            chartUIView.view.isUserInteractionEnabled = true
            addChild(chartUIView)
            viewTableOrChart.addSubview(chartUIView.view)
            view.addConstraint(chartUIView.view.centerXAnchor.constraint(equalTo: self.viewTableOrChart.centerXAnchor))
            view.addConstraint(chartUIView.view.centerYAnchor.constraint(equalTo: self.viewTableOrChart.centerYAnchor))
            
            chartUIView.didMove(toParent: self)
        }
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
    
    func togglePickerView() {
//        settingView.autoresizesSubviews = false
//        UIView.animate(withDuration: 0.0, delay: 0, options: [.beginFromCurrentState], animations: {
//            self.datePicker.isHidden.toggle()
//            self.rangeView.layoutIfNeeded()
//            self.showDataBtn.layoutIfNeeded()
//            self.btnAddData.layoutIfNeeded()
//        })
//        settingView.autoresizesSubviews = true
        self.datePicker.isHidden.toggle()
    }
    
    func hidePickerView() {
//        UIView.animate(withDuration: 0.5, animations: {
//            self.datePicker.isHidden = true
//            self.rangeView.layoutIfNeeded()
//            self.showDataBtn.layoutIfNeeded()
//            self.btnAddData.layoutIfNeeded()
//        })
        datePicker.isHidden = true
    }
    
    func selectedDayToString() -> String {
        let formatter = DateFormatter()
        switch selectedRange {
        case .week:
            formatter.dateFormat = "yyyy, MMM dd"
        case .month:
            formatter.dateFormat = "yyyy, MMM"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: selectedDay)
    }
    
    func numberOfDays(inMonth month: Int, forYear year: Int) -> Int {
        let current = Calendar.current
        if let date = current.date(from: DateComponents(year: year, month: month)),
           let range = current.range(of: .day, in: .month, for: date) {
            return range.count
        } else {
            return 0
        }
    }
    
    func endOfMonth(year: Int, month: Int) -> Date {
        let calendar = Calendar.current
        
        var endOfMonthComponents = DateComponents(year: year, month: month)
        endOfMonthComponents.day = calendar.range(of: .day, in: .month,
                                                  for: calendar.date(from: endOfMonthComponents)!)!.upperBound - 1
        
        return calendar.date(from: endOfMonthComponents)!
    }
    
    func endOfYear(year: Int) -> Date {
        let calendar = Calendar.current
        let endOfYearComponents = DateComponents(year: year, month: 12, day: 31)
        
        return calendar.date(from: endOfYearComponents)!
        
    }
    
    func beginOfMonth(year: Int, month: Int) -> Date {
        let calendar = Calendar.current
        let startOfMonthComponents = DateComponents(year: year, month: month, day: 1)
        
        return calendar.date(from: startOfMonthComponents)!
    }

    func beginOfYear(year: Int) -> Date {
        let calendar = Calendar.current
        let startOfYearComponents = DateComponents(year: year, month: 1, day: 1)
        
        return calendar.date(from: startOfYearComponents)!
    }
    
    @IBAction func clickedShow(_ sender: Any) {
        showData()
        hidePickerView()
    }

    @IBAction func clinkedAddData(_ sender: Any) {
        hidePickerView()
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
    
    @IBAction func dateBtnTapped(_ sender: Any) {
        togglePickerView()
    }
    
    @objc func tappedOutside(_ gesture: UITapGestureRecognizer) {
        hidePickerView()
    }
    
    @objc func animateView() {
        hidePickerView()
        self.settingParent.isUserInteractionEnabled = self.isCollapsed
        isCollapsed = !isCollapsed
        
        UIView.transition(with: settingParent, duration: 0.5, animations: {
            self.settingView.isHidden = self.isCollapsed
            self.settingParent.layoutIfNeeded()
            self.spacerView.alpha = self.isCollapsed ? 0 : 0.5
        })
    }
    
    @IBAction func clickedShowChart(_ sender: Any) {
        if dataValues.count == 0 {
            return
        }
        toggleView()
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
        if selectedRange == .year {
            dateformatter.dateFormat = "MMM yyyy"
        } else {
            dateformatter.dateFormat = "MM/dd/yyyy"
        }
        
        cell.textLabel?.text = "\(value.displayString) \(getUnit(for: dataTypeIdentifier) ?? "")"
        cell.detailTextLabel?.text = dateformatter.string(from: value.startDate)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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

extension HealthDisplayViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch selectedRange {
        case .week:
            return 3
        case .month:
            return 2
        case .year:
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return yearOption.count
        }
        
        if component == 1 {
            return monthOption.count
        }
        
        if component == 2 {
            return numberOfDays(inMonth: selectMonth, forYear: selectYear)
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "\(yearOption[row])"
        }
        
        if component == 1 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            guard let monthDate = Calendar.current.date(from: DateComponents(month: monthOption[row])) else {
                return nil
            }
            
            return dateFormatter.string(from: monthDate)
        }
        
        if component == 2 {
            return "\(row + 1)"
        }
        
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectYear = yearOption[row]
        }
        
        if component == 1 {
            selectMonth = monthOption[row]
        }
        
        if component == 2 {
            selectDay = row + 1
        }
        
        dateBtn.setTitle(selectedDayToString(), for: .normal)
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 0 {
            return pickerView.frame.width / 3.0
        }
        
        if component == 2 {
            return pickerView.frame.width / 5.0
        }
        
        if component == 1 {
            return pickerView.frame.width * (7.0 / 15.0)
        }
        
        return 0
    }
}

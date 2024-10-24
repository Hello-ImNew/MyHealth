//
//  CategoryDisplayViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 11/30/23.
//

import UIKit
import HealthKit
import SwiftUI

enum rangeOption: String {
    case week = "1 Week"
    case month = "1 Month"
    case year = "1 Year"
}

class CategoryDisplayViewController: UIViewController, AddDataDelegate {
    enum displayMode: Int {
        case chart = 0
        case condenseChart
        case table
        case scatterChart
    }
    
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var rangeView: UIView!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var settingView: UIView!
    @IBOutlet weak var settingStack: UIStackView!
    @IBOutlet weak var addDataBtn: UIButton!
    @IBOutlet weak var condenseChartBtn: UIButton!
    @IBOutlet weak var rangeBtn: UIButton!
    @IBOutlet weak var dateBtn: UIButton!
    @IBOutlet weak var datePicker: UIPickerView!
    //@IBOutlet weak var settingParent: UIStackView!
    @IBOutlet weak var spacerView: UIView!
    
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    let healthStore = HealthData.healthStore
    var mode: displayMode!
    var isCollapse: Bool = false
    var dataValues: [categoryDataValue] = []
    var dataTypeIdentifier: String = ""
    
    var selectedRange: rangeOption = .week
    var selectDay: Int = Calendar.current.component(.day, from: Date())
    var selectMonth: Int = Calendar.current.component(.month, from: Date())
    var selectYear: Int = Calendar.current.component(.year, from: Date())
    
    let yearOption: [Int] = Array(2015...(Calendar.current.component(.year, from: Date()) + 5))
    let monthOption: [Int] = Array(1...12)
    let rangeOptions: [rangeOption] = [.week, .month, .year]
    
    var selectedDay: Date {
        let date = Calendar.current.date(from: DateComponents(year: selectYear, month: selectMonth, day: selectDay))
        
        return date!
    }
    
    var start: Date {
        var res: Date
        switch selectedRange {
        case .week:
            res = endOfDay(Calendar.current.date(byAdding: .day, value: -6, to: selectedDay)!)
        case .month:
            res = beginOfMonth(year: selectYear, month: selectMonth)
        case .year:
            res = beginOfYear(year: selectYear)
        }
        if dataTypeIdentifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
            res = Calendar.current.date(byAdding: .hour, value: -6, to: res)!
        }
        
        return res
    }
    
    var end: Date {
        var res: Date
        switch selectedRange {
        case .week:
            res = Calendar.current.startOfDay(for: selectedDay)
        case .month:
            res = endOfMonth(year: selectYear, month: selectMonth)
        case .year:
            res = endOfYear(year: selectYear)
        }
        
        if dataTypeIdentifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
            res = Calendar.current.date(byAdding: .hour, value: -6, to: res)!
        }
        
        return res
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
        
        datePicker.delegate = self
        datePicker.dataSource = self
        
        self.title = currentTitle
        
        if ViewModels.notificationType.contains(where: {$0 == dataTypeIdentifier}) {
            mode = .table
        } else {
            if ViewModels.scatterChartType.contains(where: {$0 == dataTypeIdentifier}) {
                mode = .scatterChart
            } else {
                mode = .chart
            }
        }
        
        if dataTypeIdentifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
            condenseChartBtn.isHidden = false
        } else {
            condenseChartBtn.isHidden = true
        }
        
        let settingButton = UIBarButtonItem(title: "Setting", style: .plain, target: self, action: #selector(settingTapped))
        self.navigationItem.rightBarButtonItem = settingButton
        
        dateBtn.setTitle(selectedDayToString(), for: .normal)
        datePicker.selectRow(yearOption.firstIndex(of: selectYear)!, inComponent: 0, animated: false)
        datePicker.selectRow(monthOption.firstIndex(of: selectMonth)!, inComponent: 1, animated: false)
        datePicker.selectRow(selectDay - 1, inComponent: 2, animated: false)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
        
        rangeView.layer.cornerRadius = 8
        dateView.layer.cornerRadius = 8
        
        settingView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10)
        
        createFavButton()
        setupRangePicker()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settingView.isHidden = true
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
                    let dataValues = result.compactMap({ element in
                        let dataValue = categoryDataValue(identifier: self.dataTypeIdentifier,
                                          startDate: element.startDate,
                                          endDate: element.endDate,
                                          value: element.value)
                        if self.dataTypeIdentifier == HKCategoryTypeIdentifier.menstrualFlow.rawValue {
                            dataValue.metadata = [HKMetadataKeyMenstrualCycleStart: element.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool ?? false]
                        }
                        return dataValue
                    })
                    
                    
                    
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
        case .scatterChart:
            addScatterChart()
        default:
            return
        }
    }
    
    func animateView(_ collapse: Bool) {
        isCollapse = collapse
        settingView.isUserInteractionEnabled = !collapse
        spacerView.isUserInteractionEnabled = !collapse
        UIView.transition(with: settingView, duration: 0.5, animations: {
            self.settingView.isHidden = collapse
            self.settingView.alpha = collapse ? 0 : 1
            self.settingView.layoutIfNeeded()
            self.spacerView.alpha = collapse ? 0 : 0.5
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
        let categoryChart = CategoryDataChart(data: self.dataValues, identifier: self.dataTypeIdentifier, startTime: self.start, endTime: self.end, range: selectedRange)
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
    
    func addScatterChart() {
        let chart = ScatterChartView(data: dataValues, identifier: dataTypeIdentifier, startTime: start, endTime: end)
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
            if self.selectedRange == .month || self.selectedRange == .week {
                self.datePicker.selectRow(self.monthOption.firstIndex(of: self.selectMonth)!, inComponent: 1, animated: false)
            }
            if self.selectedRange == .week {
                self.datePicker.selectRow(self.selectDay - 1, inComponent: 2, animated: false)
            }
        }
        
        let options = rangeOptions.map({ element in
            return UIAction(title: element.rawValue, handler: rangeClosure)
        })
        
        options[0].state = .on
        rangeBtn.changesSelectionAsPrimaryAction = true
        rangeBtn.showsMenuAsPrimaryAction = true
        rangeBtn.menu = UIMenu(title: "Choose time range", children: options)
    }
    
    @objc func tappedOutside(_ gesture: UITapGestureRecognizer) {
        hidePickerView()
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
    
    func togglePickerView() {
//        UIView.animate(withDuration: 0.5, animations: {
//            self.datePicker.isHidden.toggle()
//        })
        datePicker.isHidden.toggle()
        
        self.settingStack.layoutIfNeeded()
        var frame = settingView.frame
        frame.size.height = settingStack.frame.height + 20
        settingView.frame = frame
        
        settingView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10)
    }
    
    func hidePickerView() {
//        UIView.animate(withDuration: 0.5, animations: {
//            self.datePicker.isHidden = true
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
    
    func endOfDay(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
    }
    
    func endOfMonth(year: Int, month: Int) -> Date {
        let calendar = Calendar.current
        
        var endOfMonthComponents = DateComponents(year: year, month: month)
        endOfMonthComponents.day = calendar.range(of: .day, in: .month,
                                                  for: calendar.date(from: endOfMonthComponents)!)!.upperBound - 1
        endOfMonthComponents.hour = 23
        endOfMonthComponents.minute = 59
        endOfMonthComponents.second = 59
        
        return calendar.date(from: endOfMonthComponents)!
    }
    
    func endOfYear(year: Int) -> Date {
        let calendar = Calendar.current
        let endOfYearComponents = DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        
        return calendar.date(from: endOfYearComponents)!
        
    }
    
    func beginOfMonth(year: Int, month: Int) -> Date {
        let calendar = Calendar.current
        let startOfMonthComponents = DateComponents(year: year, month: month, day: 1, hour: 0, minute: 0, second: 0)
        
        return calendar.date(from: startOfMonthComponents)!
    }

    func beginOfYear(year: Int) -> Date {
        let calendar = Calendar.current
        let startOfYearComponents = DateComponents(year: year, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        
        return calendar.date(from: startOfYearComponents)!
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
    
    @IBAction func addDataTapped(_ sender: Any) {
        if ViewModels.categoryValueType.contains(dataTypeIdentifier) {
            performSegue(withIdentifier: "AddCategoryValueSegue", sender: self)
            return
        }
        if ViewModels.scatterChartType.contains(dataTypeIdentifier) {
            performSegue(withIdentifier: "AddCategoryScatterValueSegue", sender: self)
            return
        }
        performSegue(withIdentifier: "AddCategoryDataSegue", sender: self)
    }
    
    @IBAction func dateBtnTapped(_ sender: Any) {
        togglePickerView()
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
            return
        }
        
        if segue.identifier == "AddCategoryValueSegue" {
            if let navController = segue.destination as? UINavigationController,
               let addCategoryController = navController.viewControllers.first as? AddCategoryValueViewController {
                addCategoryController.identifier = dataTypeIdentifier
                addCategoryController.delegate = self
            }
            return
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

extension CategoryDisplayViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
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


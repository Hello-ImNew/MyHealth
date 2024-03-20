//
//  UploadDataViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 3/14/24.
//

import UIKit

class UploadDataViewController: UIViewController {
    
    @IBOutlet weak var btnSelectDate: UIButton!
    @IBOutlet weak var datePicker: UIPickerView!
    @IBOutlet weak var rangePicker: UIButton!
    
    var selectedRange: rangeOption = .week
    var selectDay: Int = Calendar.current.component(.day, from: Date())
    var selectMonth: Int = Calendar.current.component(.month, from: Date())
    var selectYear: Int = Calendar.current.component(.year, from: Date())
    var selectedDay: Date {
        let date = Calendar.current.date(from: DateComponents(year: selectYear, month: selectMonth, day: selectDay))
        
        return date!
    }
    
    var startDay: Date {
        switch selectedRange {
        case .week:
            return Date()
        case .month:
            return beginOfMonth(year: selectYear, month: selectMonth)
        case .year:
            return beginOfYear(year: selectYear)
        }
    }
    
    var endDate: Date {
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
    
    enum rangeOption: String {
        case week = "1 Week"
        case month = "1 Month"
        case year = "1 Year"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        datePicker.delegate = self
        datePicker.dataSource = self
        
        
        btnSelectDate.setTitle(selectedDayToString(), for: .normal)
        datePicker.selectRow(yearOption.firstIndex(of: selectYear)!, inComponent: 0, animated: false)
        datePicker.selectRow(monthOption.firstIndex(of: selectMonth)!, inComponent: 1, animated: false)
        datePicker.selectRow(selectDay - 1, inComponent: 2, animated: false)
        
        setupRangePicker()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
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
            
            self.btnSelectDate.setTitle(self.selectedDayToString(), for: .normal)
            self.datePicker.reloadAllComponents()
        }
        
        let options = rangeOptions.map({ element in
            return UIAction(title: element.rawValue, handler: rangeClosure)
        })
        
        options[0].state = .on
        rangePicker.changesSelectionAsPrimaryAction = true
        rangePicker.showsMenuAsPrimaryAction = true
        rangePicker.menu = UIMenu(title: "Choose time range", children: options)
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
        UIView.animate(withDuration: 0.5, animations: {
            self.datePicker.isHidden.toggle()
        })
    }
    
    func hidePickerView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.datePicker.isHidden = true
        })
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
    
    func endOfMonth(year: Int, month: Int) -> Date {
        var calendar = Calendar.current
        
        var endOfMonthComponents = DateComponents(year: year, month: month)
        endOfMonthComponents.day = calendar.range(of: .day, in: .month, 
                                                  for: calendar.date(from: endOfMonthComponents)!)!.upperBound - 1
        
        return calendar.date(from: endOfMonthComponents)!
    }
    
    func endOfYear(year: Int) -> Date {
        var calendar = Calendar.current
        var endOfYearComponents = DateComponents(year: year, month: 12, day: 31)
        
        return calendar.date(from: endOfYearComponents)!
        
    }
    
    func beginOfMonth(year: Int, month: Int) -> Date {
        var calendar = Calendar.current
        var startOfMonthComponents = DateComponents(year: year, month: month, day: 1)
        
        return calendar.date(from: startOfMonthComponents)!
    }

    func beginOfYear(year: Int) -> Date {
        var calendar = Calendar.current
        var startOfYearComponents = DateComponents(year: year, month: 1, day: 1)
        
        return calendar.date(from: startOfYearComponents)!
    }
    
    @IBAction func dateTapped(_ sender: Any) {
        togglePickerView()
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

extension UploadDataViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
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
        
        btnSelectDate.setTitle(selectedDayToString(), for: .normal)
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

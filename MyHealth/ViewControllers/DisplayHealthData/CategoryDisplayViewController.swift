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
    
    @IBOutlet weak var dpkStart: UIDatePicker!
    @IBOutlet weak var dpkEnd: UIDatePicker!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var settingView: UIStackView!
    
    let healthStore = HealthData.healthStore
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = currentTitle
        dpkStart.date = start
        dpkEnd.date = end
        dpkStart.maximumDate = dpkEnd.date
        dpkEnd.minimumDate = dpkStart.date
        
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
            let shareType = Set([sampleType!])
            HealthData.requestHealthDataAccessIfNeeded(toShare: shareType, read: readType) {success in 
                if success {
                    self.categoryQuery(for: sampleType!) {results in 
                        DispatchQueue.main.async {
                            self.animateView(true)
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
//                            self.view.addConstraint(categoryChartController.view.centerXAnchor.constraint(equalTo: self.chartView.centerXAnchor))
//                            self.view.addConstraint(categoryChartController.view.centerYAnchor.constraint(equalTo: self.chartView.centerYAnchor))
                            NSLayoutConstraint.activate([
                                categoryChartController.view.topAnchor.constraint(equalTo: self.chartView.topAnchor),
                                categoryChartController.view.leadingAnchor.constraint(equalTo: self.chartView.leadingAnchor),
                                categoryChartController.view.trailingAnchor.constraint(equalTo: self.chartView.trailingAnchor),
                                categoryChartController.view.bottomAnchor.constraint(equalTo: self.chartView.bottomAnchor),
                            ])
                            
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
                    let dataValues = result.compactMap({categoryDataValue(identifier: self.dataTypeIdentifier, startDate: $0.startDate, endDate: $0.endDate, value: $0.value)})
                    
                    completion(dataValues)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    @objc func settingTapped() {
        animateView(!isCollapse)
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

//
//  PDFPreviewViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 1/23/24.
//

import UIKit
import HealthKit
import PDFKit

class PDFPreviewViewController: UIViewController {
    
    @IBOutlet weak var PDFPreview: PDFView!
    
    var categoryIndex: Int? = nil
    var dataList = Set<HKSampleType>()
    var startDate: Date!
    var endDate: Date!

    override func viewDidLoad() {
        super.viewDidLoad()
        requestAuthorize {
            let pdfCreator: PDFCreator
            if let index = self.categoryIndex {
                pdfCreator = PDFCreator(category: index, startTime: self.startDate, endTime: self.endDate)
            } else {
                pdfCreator = PDFCreator(dataTypes: self.dataList, startTime: self.startDate, endTime: self.endDate)
            }
            pdfCreator.createPDF() { data in
                self.PDFPreview.document = PDFDocument(data: data)
                self.PDFPreview.autoScales = true
            }
        }
    }
    
    @IBAction func sharePDF(_ sender: Any) {
        requestAuthorize {
            let pdfCreator: PDFCreator
            if let index = self.categoryIndex {
                pdfCreator = PDFCreator(category: index, startTime: self.startDate, endTime: self.endDate)
            } else {
                pdfCreator = PDFCreator(dataTypes: self.dataList, startTime: self.startDate, endTime: self.endDate)
            }
            pdfCreator.createPDF() { data in
                let vc = UIActivityViewController(activityItems: [data], applicationActivities: [])
                self.present(vc, animated: true)
            }
        }
    }
    
    func requestAuthorize(completion: @escaping () -> Void) {
        if let index = categoryIndex {
            var types: [HKSampleType] {
                var res: [HKSampleType] = []
                for type in ViewModels.HealthCategories[index].dataTypes {
                    if type is HKQuantityType {
                        res.append(type)
                    }
                }
                return res
            }
            dataList = Set(types)
        }
        // Do any additional setup after loading the view.
        HealthData.requestHealthDataAccessIfNeeded(toShare: nil, read: dataList) { success in
            if success {
                DispatchQueue.main.async {
                    completion()
                }
            }
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

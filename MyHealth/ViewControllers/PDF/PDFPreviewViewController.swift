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
    
    var dataList = Set<HKSampleType>()
    var startDate: Date!
    var endDate: Date!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        HealthData.requestHealthDataAccessIfNeeded(toShare: nil, read: dataList) { success in
            if success {
                DispatchQueue.main.async {
                    
                    let pdfCreator = PDFCreator(dataTypes: self.dataList, startTime: self.startDate, endTime: self.endDate)
                    pdfCreator.createPDF() { data in
                        self.PDFPreview.document = PDFDocument(data: data)
                        self.PDFPreview.autoScales = true
                    }
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

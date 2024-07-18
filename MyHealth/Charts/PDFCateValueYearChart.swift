//
//  PDFCateValueYearChart.swift
//  MyHealth
//
//  Created by Bao Bui on 5/21/24.
//

import SwiftUI
import Charts

struct PDFCateValueYearData {
    let month: Int
    var value: TimeInterval
}

struct PDFCateValueYearChart: View {
    let dayInSec = 24*60*60
    let identifier: String
    let start: Date
    let end: Date
    let data: [categoryDataValue]
    let frame: CGRect
    let color = Color.gray
    
    var processedData: [PDFCateValueYearData] {
        var res: [PDFCateValueYearData] = []
        for i in 1...12 {
            res.append(PDFCateValueYearData(month: i, value: 0))
        }
        
        for d in data {
            let month = Calendar.current.component(.month, from: d.startDate)
            let i = res.firstIndex(where: {$0.month == month})
            if let index = i {
                res[index].value += d.endDate.timeIntervalSince(d.startDate)
            }
        }
        return res
    }
    
    var unit : String {
        if let maxInterval = processedData.max(by: {$0.value < $1.value})?.value {
            if maxInterval > 3600*1.5 {
                return "hrs"
            } else {
                return "min"
            }
        } else {
            return "min"
        }
        
    }
    
    var body: some View {
        VStack {
            Chart {
                ForEach(processedData, id: \.month) { d in
                    BarMark(x: .value("Date", d.month),
                            y: .value("Time", intervalToTime(d.value)))
                    .foregroundStyle(color)
                }
            }
            .if(!processedData.contains(where: {$0.value != 0})) { view in
                view.chartYScale(domain: 1...10)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 1)) {
                    if let month = $0.as(Int.self) {
                        AxisValueLabel {
                            Text("\(getXlabel(for: month))")
                        }
                    }
                }
            }
        }
        .padding(.all, 5)
        .frame(width: frame.width, height: frame.height)
        .preferredColorScheme(.light)
    }
    
    func intervalToTime(_ interval: TimeInterval) -> Double {
        if unit == "min" {
            return interval / 60
        } else {
            return interval / 3600
        }
    }
    
    func getXlabel(for month: Int) -> String {
        let date = Calendar.current.date(from: DateComponents(month: month))!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return String(formatter.string(from: date).first!)
    }
}

//
//  PDFCateValueChart.swift
//  MyHealth
//
//  Created by Bao Bui on 5/6/24.
//

import SwiftUI
import Charts

struct PDFCateValueChart: View {
    let dayInSec = 24*60*60
    let identifier: String
    let start: Date
    let end: Date
    let data: [categoryDataValue]
    let frame: CGRect
    let range: rangeOption
    
    let color = Color.gray
    var unit : String {
        if let maxInterval = data.compactMap({$0.endDate.timeIntervalSince($0.startDate)}).max() {
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
                ForEach(data) { d in
                    BarMark(x: .value("Date", d.startDate, unit: .day),
                            y: .value("Time", intervalToTime(d.endDate.timeIntervalSince(d.startDate))))
                    .foregroundStyle(color)
                }
            }
            .if(data.isEmpty) { view in
                view.chartYScale(domain: 0...10)
            }
            .chartXScale(domain: start...end)
            .chartXAxis {
                if range == .week {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text("\(getXLabel(date))")
                            }
                        }
                    }
                } else if range == .month {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text("\(getXLabel(date))")
                            }
                        }
                    }
                }
            }
            .chartYAxis(content: {
                AxisMarks { value in
                    if let value = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(getYLabel(value))")
                        }
                    }
                    AxisGridLine()
                }
            })
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
    
    func getXLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch self.range {
        case .week:
            formatter.dateFormat = "EEE"
            return String(formatter.string(from: date).first!)
        case .month:
            formatter.dateFormat = "d"
            return formatter.string(from: date)
        case .year:
            return ""
        }
    }
    
    func getYLabel(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        return formatter.string(from: value as NSNumber)!
    }
}

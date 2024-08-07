//
//  PDFChart.swift
//  MyHealth
//
//  Created by Bao Bui on 2/9/24.
//

import Foundation
import SwiftUI
import Charts

struct PDFChart: View {
    let dayInSec = 24*3600
    let data: [quantityDataValue]
    let frame: CGRect
    let color = Color.gray
    let range: rangeOption
    var timelineUnit: Calendar.Component {
        switch range {
        case .week, .month:
            return .day
        case .year:
            return.month
        }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return formatter
    }
    var body: some View {
        VStack{
            Chart {
                ForEach(data) { d in
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: timelineUnit),
                            y: .value("Value", d.secondaryValue ?? 0))
                    .foregroundStyle(.clear)
                    
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: timelineUnit),
                            y: .value("Value", d.value - (d.secondaryValue ?? 0)))
                    .foregroundStyle(color)
                }
            }
            .chartXAxis(content: {
                if range == .year {
                    AxisMarks(values: .stride(by: .month, count: 1)) {
                        let value = $0.as(Date.self)!
                        AxisValueLabel {
                            Text("\(getLabel(value))")
                        }
                    }
                }
                
                if range == .month {
                    AxisMarks(values: .automatic(desiredCount: 6)) {
                        let value = $0.as(Date.self)!
                        AxisValueLabel {
                            Text("\(getLabel(value))")
                        }
                    }
                }
                
                if range == .week {
                    AxisMarks(values: .stride(by: .day, count: 1)) {
                        let value = $0.as(Date.self)!
                        AxisValueLabel {
                            Text("\(getLabel(value))")
                        }
                    }
                }
            })
            .if((!data.contains(where: {$0.value != 0 || ($0.secondaryValue ?? 0) != 0})) || (data.isEmpty)) {view in
                view.chartYScale(domain: 0...10)
            }
        }
        .padding(.all, 5)
        .frame(width: frame.width, height: frame.height)
        .preferredColorScheme(.light)
    }
    
    
    
    func getLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch self.range {
        case .week:
            formatter.dateFormat = "EEE"
            return String(formatter.string(from: date).first!)
        case .month:
            formatter.dateFormat = "d"
            return formatter.string(from: date)
        case .year:
            formatter.dateFormat = "MMM"
            return String(formatter.string(from: date).first!)
        }
    }
}

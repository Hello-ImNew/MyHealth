//
//  PDFHorBarChart.swift
//  MyHealth
//
//  Created by Bao Bui on 4/29/24.
//

import SwiftUI
import Charts

struct PDFHorBarChart: View {
    let identifier: String
    let start: Date
    let end: Date
    let data: [categoryDataValue]
    let frame: CGRect
    let color = Color.gray
    let range: rangeOption
    
    let dayInSec = 24*3600
    var timelineUnit: Calendar.Component {
        switch range {
        case .week, .month:
            return .day
        case .year:
            return.month
        }
    }
    
    var body: some View {
        VStack {
            Chart {
                ForEach(data) {d in
                    RuleMark(xStart: .value("Start", d.startDate, unit: .minute),
                             xEnd: .value("End", d.endDate, unit: .minute),
                             y: .value("Value", getCategoryValues(for: d.identifier)[d.value]))
                    .lineStyle(StrokeStyle(lineWidth: 5, lineCap: .round))
                    .foregroundStyle(color)
                }
            }
            .chartYScale(domain: getCategoryValues(for: identifier).reversed())
            .chartXScale(domain: Calendar.current.startOfDay(for: start)...beginningOfNextDay(end))
            .chartXAxis {
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
        case .month:
            formatter.dateFormat = "d"
            return formatter.string(from: date)
        case .year:
            formatter.dateFormat = "MMM"
        }
        
        return String(formatter.string(from: date).first!)
    }
}

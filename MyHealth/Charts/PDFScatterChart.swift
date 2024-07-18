//
//  PDFScatterChart.swift
//  MyHealth
//
//  Created by Bao Bui on 5/23/24.
//

import SwiftUI
import Charts
import HealthKit

struct PDFScatterChart: View {
    let identifier: String
    let start: Date
    let end: Date
    let data: [categoryDataValue]
    let frame: CGRect
    let color = Color.gray
    let range: rangeOption
    
    let dayInSec = 24*3600
    
    var body: some View {
        VStack {
            Chart {
                ForEach(data) { d in
                    PointMark(x: .value("Time", d.startDate, unit: .minute),
                              y: .value("Value", getCategoryValues(for: identifier)[d.value]))
                    .symbol {
                        if let isCycleStart = d.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool,
                           isCycleStart == true {
                            Image(systemName: "circle")
                                .foregroundStyle(Color(uiColor: .systemBlue))
                                .font(.system(size: 5))
                        } else {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(Color(uiColor: .systemBlue))
                                .font(.system(size: 5))
                        }
                    }
                }
            }
            .chartXScale(domain: Calendar.current.startOfDay(for: start)...beginningOfNextDay(end))
            .chartYScale(domain: getCategoryValues(for: identifier)[1...])
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
        switch range {
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

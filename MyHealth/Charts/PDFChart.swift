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
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return formatter
    }
    var body: some View {
        VStack{
            Chart {
                ForEach(data) { d in
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: .day),
                            y: .value("Value", d.secondaryValue ?? 0))
                    .foregroundStyle(.clear)
                    
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: .day),
                            y: .value("Value", d.value))
                    .foregroundStyle(color)
                }
            }
            .chartXAxis(content: {
                AxisMarks(content: {value in
                    let date = value.as(Date.self)!
                    AxisValueLabel {
                        Text("\(dateFormatter.string(from: date))")
                    }
                    AxisGridLine()
                })
            })
        }
        .padding(.all, 5)
        .frame(width: frame.width, height: frame.height)
        .preferredColorScheme(.light)
    }
}

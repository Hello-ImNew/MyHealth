//
//  SummaryChartView.swift
//  MyHealth
//
//  Created by Bao Bui on 10/12/23.
//

import Foundation
import SwiftUI
import Charts

struct SummaryChartView: View {
    let dataIdentifier: String
    let data:[quantityDataValue]
    let pastDataColor : Color = .gray
    let todayDataColor : Color = .orange
    
    var body: some View {
        VStack{
            Chart {
                ForEach(data) {d in
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: .day), y: .value("Value", d.secondaryValue ?? 0))
                        .foregroundStyle(.clear)
                }
                ForEach(data) {d in
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: .day), y: .value("Value", d.value - (d.secondaryValue ?? 0)))
                        .foregroundStyle(Calendar.current.isDateInToday(d.startDate) ? todayDataColor : pastDataColor)
                        .alignsMarkStylesWithPlotArea()
                }
            }
            .chartYAxis() {}
            .chartXAxis() {}
            .frame(width: 85, height: 65)
            .background(Color(UIColor.secondarySystemGroupedBackground))

        }
        .padding()
        .onAppear()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        
    }
}

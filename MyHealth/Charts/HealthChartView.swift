//
//  HealthChartView.swift
//  MyHealth
//
//  Created by Bao Bui on 10/3/23.
//

import Foundation
import SwiftUI
import Charts

@available(iOS 17.0, *)
struct HealthChartView: View {
    let dayInSec = 24*3600
    let dataIdentifier: String
    let data:[HealthDataValue]
    let pastDataColor : LinearGradient = .linearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
    let todayDataColor : LinearGradient = .linearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
    
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
            .frame(width: 350, height: 300, alignment: .center)
            .chartYAxisLabel("\(getDataTypeName(for: dataIdentifier) ?? "") (\(getUnit(for: dataIdentifier) ?? ""))")
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: data.count <= 7 ? dayInSec*data.count : dayInSec*7)
            .chartScrollPosition(initialX: data.count > 7 ? data[data.count - 7].startDate : data[0].startDate)
        }
        .padding()
        .onAppear()
        
    }
}

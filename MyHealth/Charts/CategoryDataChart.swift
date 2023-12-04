//
//  CategoryDataChart.swift
//  MyHealth
//
//  Created by Bao Bui on 11/30/23.
//

import Foundation
import SwiftUI
import Charts

struct CategoryDataChart: View {
    
    var data: [categoryDataValue]
    var identifier: String
    var startTime: Date
    var endTime: Date
    
    var body: some View {
        VStack {
            Chart {
                ForEach(data) { datum in
                    RuleMark(xStart: .value("date", datum.startDate, unit: .minute),
                             xEnd: .value("date", datum.endDate, unit: .minute),
                             y: .value("value", getCategoryValues(for: datum.identifier)[datum.value]))
                    .lineStyle(StrokeStyle(lineWidth: 10, lineCap: .round))
                    .foregroundStyle(by: .value("Color", getCategoryValues(for: datum.identifier)[datum.value]))
                }
            }
            .chartYScale(domain: getCategoryValues(for: identifier).reversed())
            .chartXScale(domain: startTime...endTime)
            .frame(width: 350, height: 300)
        }
        .padding()
    }
}

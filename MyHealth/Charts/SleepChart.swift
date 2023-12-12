//
//  SleepChart.swift
//  MyHealth
//
//  Created by Bao Bui on 11/7/23.
//

import Foundation
import SwiftUI
import HealthKit
import Charts

struct SleepChart: View {
    let data: [HKCategorySample]
    let halfDayInSec = 12*3600
    
    var body: some View {
        VStack {
            Chart {
                ForEach(data, id:\.self) {d in
                    BarMark(
                        xStart: .value("Start", d.startDate, unit: .minute),
                        xEnd: .value("End", d.endDate, unit: .minute),
                        y: .value("Value", d.value),
                        height: .automatic)
                    .foregroundStyle(by: .value("Color", intToSleepStage(value: d.value)))
                }
                
            }
            .chartYScale(domain: -0.5...5.5)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: halfDayInSec)
            .chartScrollTargetBehavior(
                .valueAligned(matching: DateComponents(minute: 0),
                              majorAlignment: .matching(DateComponents(hour: 0)))
            )
            .chartYAxis {
                AxisMarks(values: [0,1,2,3,4,5]) {
                    let value = $0.as(Int.self)!
                    AxisValueLabel {
                        Text("\(intToSleepStage(value: value))")
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 1)) { value in
                    if let date = value.as(Date.self) {
                        let hour = Calendar.current.component(.hour, from: date)
                        AxisValueLabel {
                            VStack(alignment: .leading){
                                Text(date, format: .dateTime.hour())
                                if value.index == 0 || hour == 0 {
                                    Text(date, format: .dateTime.month().day())
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func intToSleepStage(value: Int) -> String {
        switch value {
        case 0: return "In Bed"
        case 1: return "Asleep"
        case 2: return "Awake"
        case 3: return "Core"
        case 4: return "Deep"
        case 5: return "REM"
        default: return ""
        }
    }
    
    
}

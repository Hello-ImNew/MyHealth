//
//  HealthChartView.swift
//  MyHealth
//
//  Created by Bao Bui on 10/3/23.
//

import Foundation
import SwiftUI
import Charts

struct HealthChartView: View {
    @State var data:[HealthDataValue] = [HealthDataValue(startDate: Date(), endDate: Date(), value: 100)]
    
    var body: some View {
        VStack{
            Chart {
                ForEach(data) {d in
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: .day), y: .value("Value", d.value))
                }
            }
            .frame(width: 350, height: 300, alignment: .center)
        }
        .padding()
        .onAppear()
        
    }
}

struct healthChartView_Preview: PreviewProvider {
    static var previews: some View {
        HealthChartView()
    }
}

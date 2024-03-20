//
//  ScatterChartView.swift
//  MyHealth
//
//  Created by Bao Bui on 3/4/24.
//

import SwiftUI
import HealthKit
import Charts

struct ScatterChartView: View {
    let dayInSec = 24*60*60
    let data: [categoryDataValue]
    let identifier: String
    var startTime: Date
    var endTime: Date
    
    @State var selectedDate: Date?
    @State var selectedData: categoryDataValue?
    
    var body: some View {
        VStack(alignment: .center, content: {
            VStack(alignment: .leading, content: {
                VStack(alignment: .leading) {
                   if let selectedData = selectedData,
                      let selectedDate = selectedDate {
                       Text("\(getDataTypeName(for: identifier)!.uppercased())")
                       Text("\(getCategoryValues(for: identifier)[selectedData.value])")
                       Text("\(selectedDate.standardString)")
                   } else {
                       Text("\(getDataTypeName(for: identifier)!.uppercased())")
                       Text("\(data.count) ").bold() + Text("entries")
                       Text("\(dateIntervalToString(from: startTime, to: endTime))")
                   }
                }
                Chart {
                    ForEach(data) {d in
                        PointMark(x: .value("Time", d.startDate, unit: .minute),
                                  y: .value("Value", getCategoryValues(for: identifier)[d.value]))
                        
                        .symbol(symbol: {
                            if let isCycleStart = d.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool,
                               isCycleStart == true {
                                Image(systemName: "circle")
                                    .foregroundStyle(Color(uiColor: .systemBlue))
                                    .font(.system(size: 10))
                                    .opacity(isHightLight(d) ? 1.0 : 0.5)
                            } else {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(Color(uiColor: .systemBlue))
                                    .font(.system(size: 10))
                                    .opacity(isHightLight(d) ? 1.0 : 0.5)
                            }
                        })
                    }
                }
                .chartXScale(domain: startTime...beginningOfNextDay(endTime))
                .chartYScale(domain: getCategoryValues(for: identifier)[1...])
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: getVisibleDomain(start: startTime, end: endTime))
                .chartScrollPosition(initialX: max(startTime, beginningOfNextDay(endTime) - TimeInterval(7*dayInSec)))
                .chartScrollTargetBehavior(
                    .valueAligned(matching: DateComponents(hour: 0),
                                  majorAlignment: .matching(
                                    DateComponents(hour: 0,
                                                   weekday: Calendar.current.component(.weekday, from: endTime) + 1))))
                .chartOverlay(content: {proxy in
                    GeometryReader {geometry in
                        ZStack(alignment: .top, content: {
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .onTapGesture(perform: { location in
                                    updateSelectedData(at: location, proxy: proxy, geometry: geometry)
                                })
                        })
                    }
                })
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1))
                }
                .frame(maxHeight: UIScreen.main.bounds.size.width - 20)
            })
            .padding(.all, 10)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .clipped()
            .layoutPriority(999)
        })
    }
    
    func getVisibleDomain(start: Date, end: Date) -> Int {
        let day = Int(ceil(end.timeIntervalSince(start) / Double(dayInSec)))
        
        return min(day*dayInSec, 7*dayInSec)
    }
    
    func updateSelectedData(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let date: Date = proxy.value(atX: xPosition) else {
            return
        }
        let sameDateData: [categoryDataValue] = data.filter({
            Calendar.current.isDate($0.startDate, inSameDayAs: date)
        })
        
        if sameDateData.isEmpty {
            selectedData = nil
            selectedDate = nil
        } else {
            selectedDate = date
            selectedData = sameDateData.min(by: {
                abs($0.startDate.timeIntervalSince(date)) < abs($1.startDate.timeIntervalSince(date))
            })
        }
        
        
    }
    
    func isHightLight(_ data: categoryDataValue) -> Bool {
        let res: Bool
        if let selectedData = selectedData {
            res = selectedData.id ==  data.id
        } else {
            res = true
        }
        let temp = data
        
        return res
    }
}
//
//#Preview {
//    ScatterChartView()
//}

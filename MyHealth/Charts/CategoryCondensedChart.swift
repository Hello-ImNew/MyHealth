//
//  CategoryCondensedChart.swift
//  MyHealth
//
//  Created by Bao Bui on 1/10/24.
//

import Foundation
import SwiftUI
import Charts

struct CategoryCondensedChart: View {
    var data: [categoryDataValue]
    var identifier: String
    var startTime: Date
    var endTime: Date
    
    let dayInSec = 60*60*24
    
    var listOfDays: [Date] {
        var res: [Date] = []
        for d in data {
            let start = Calendar.current.date(byAdding: .hour, value: 6, to: d.startDate)!
            if !res.contains(where: {Calendar.current.isDate($0, inSameDayAs: start)}) {
                res.append(start)
            }
        }
        return res
    }
    @State var selectedDate: Date?
    @State var selectedData: [(start: Date, end: Date)] = []
    @State var viewHeight: CGFloat = 0
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, content: {
                VStack(alignment: .leading) {
                    if let date = selectedDate,
                       !selectedData.isEmpty {
                        Text("SLEEP")
                        var timeInterval: Int {
                            var result = 0.0
                            for (start, end) in selectedData {
                                result += end.timeIntervalSince(start)
                            }
                            
                            return Int(result)
                        }
                        HStack {
                            let hr = Int(timeInterval / 3600)
                            if hr > 0 {
                                Text("\(hr)").bold() + Text(" hr")
                            }
                            let min = Int((timeInterval % 3600)/60)
                            if min > 0 {
                                Text("\(min)").bold() + Text(" min")
                            }
                            let sec = timeInterval % 60
                            if sec > 0 {
                                Text("\(sec)").bold() + Text(" sec")
                            }
                            
                            if timeInterval == 0 {
                                Text("No Data").bold()
                            }
                        }
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                    } else {
                        Text("AVERAGE")
                        var timeInterval: Int {
                            guard !listOfDays.isEmpty else {
                                return 0
                            }
                            
                            var result = 0.0
                            for (start, end) in mergeTimeIntervals(data: data) {
                                result += end.timeIntervalSince(start)
                            }
                            return Int(result/Double(listOfDays.count))
                        }
                        HStack {
                            let hr = Int(timeInterval / 3600)
                            if hr > 0 {
                                Text("\(hr)").bold() + Text(" hr")
                            }
                            let min = Int((timeInterval % 3600)/60)
                            if min > 0 {
                                Text("\(min)").bold() + Text(" min")
                            }
                            let sec = timeInterval % 60
                            if sec > 0 {
                                Text("\(sec)").bold() + Text(" sec")
                            }
                            
                            if timeInterval == 0 {
                                Text("No Data").bold()
                            }
                        }
                        Text(dateIntervalToString(from: startTime, to: endTime))
                    }
                }
                Chart {
                    ForEach(data) { d in
                        let current = Calendar.current
                        let datum = categoryDataValue(identifier: d.identifier,
                                                      startDate: current.date(byAdding: .hour, value: 6, to: d.startDate)!,
                                                      endDate: current.date(byAdding: .hour, value: 6, to: d.endDate)!,
                                                      value: d.value)
                        
                        let yStart: Double = Double(current.component(.hour, from: datum.startDate)) + Double(current.component(.minute, from: datum.startDate))/60.0
                        let yEnd: Double = Double(current.component(.hour, from: datum.endDate)) + Double(current.component(.minute, from: datum.endDate))/60.0
                        
                        if current.isDate(datum.startDate, inSameDayAs: datum.endDate) {
                            BarMark(x: .value("Date", datum.startDate, unit: .day),
                                    yStart: .value("StartTime", yStart),
                                    yEnd: .value("EndTime", yEnd))
                            .foregroundStyle(by: .value("Color", getCategoryValues(for: identifier)[datum.value]))
                        } else {
                            BarMark(x: .value("Date", datum.startDate, unit: .day),
                                    yStart: .value("StartTime", yStart),
                                    yEnd: .value("EndTime", 24))
                            .foregroundStyle(by: .value("Color", getCategoryValues(for: identifier)[datum.value]))
                            
                            BarMark(x: .value("Date", datum.endDate, unit: .day),
                                    yStart: .value("StartTime", 0),
                                    yEnd: .value("EndTime", yEnd))
                            .foregroundStyle(by: .value("Color", getCategoryValues(for: identifier)[datum.value]))
                        }
                    }
                }
                .chartYScale(domain: 0...24)
                .chartXScale(domain: startTime...Calendar.current.startOfDay(
                    for: Calendar.current.date(byAdding: .day, value: 1, to: endTime)!))
                .chartYAxis {
                    AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                        if let hr = value.as(Int.self) {
                            AxisValueLabel {
                                Text("\((abs(hr-6) - 1) % 12 + 1)\(hr - 6 < 0 || hr - 6 >= 12 ? "pm" : "am")")
                            }
                            AxisGridLine()
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1))
                }
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: getVisibleDomain(start: startTime, end: endTime))
                .chartScrollPosition(initialX: max(startTime, beginningOfNextDay(endTime) - TimeInterval(7*dayInSec)))
                .chartScrollTargetBehavior(
                    .valueAligned(matching: DateComponents(hour: 0),
                                  majorAlignment: .matching(DateComponents(hour: 0, weekday: Calendar.current.component(.weekday, from: endTime) + 1)))
                )
                .chartOverlay(content: { proxy in
                    GeometryReader {geometry in
                        ZStack(alignment: .top, content: {
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .onTapGesture { location in
                                    updateSelectedDate(at: location, proxy: proxy, geometry: geometry)
                                }
                        })
                    }
                })
                .frame(maxHeight: UIScreen.main.bounds.size.width - 20)
            })
            .padding(.all, 10)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .clipped()
            .background(Color(UIColor.secondarySystemBackground))
        }
        
    }
    
    func addDate(to list: inout [Date], _ newDate: Date) -> Bool? {
        list.append(newDate)
        return nil
    }
    
    func updateSelectedDate(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let date: Date = proxy.value(atX: xPosition) else {
            return
        }
        selectedData = []
        selectedDate = nil
        let data = mergeTimeIntervals(data: self.data).filter({
            Calendar.current.isDate(date, 
                                    inSameDayAs: Calendar.current.date(byAdding: .hour, value: 6, to: $0.start)!)
        })
        
        if !data.isEmpty {
            selectedData = data
            selectedDate = date
        }
    }
    
    func getVisibleDomain(start: Date, end: Date) -> Int {
        let day = Int(ceil(end.timeIntervalSince(start) / Double(dayInSec)))
        
        return min(day*dayInSec, 7*dayInSec)
    }
    
    func beginningOfNextDay(_ date: Date) -> Date {
        let current = Calendar.current
        let result = current.startOfDay(for: current.date(byAdding: .day, value: 1, to: date)!)
        return result
    }
}

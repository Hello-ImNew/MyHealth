//
//  CategorySingleValueChart.swift
//  MyHealth
//
//  Created by Bao Bui on 12/14/23.
//

import SwiftUI
import Charts

struct CategorySingleValueChart: View {
    let dayInSec = 24*60*60
    let pastDataColor : LinearGradient = .linearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
    let todayDataColor : LinearGradient = .linearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
    var data: [categoryDataValue]
    var identifier: String
    var startTime: Date
    var endTime: Date
    
    var unit : String {
        if let maxInterval = data.compactMap({$0.endDate.timeIntervalSince($0.startDate)}).max() {
            if maxInterval > 3600*1.5 {
                return "hrs"
            } else {
                return "min"
            }
        } else {
            return "min"
        }
        
    }
    @State var selectedDate: Date?
    @State var selectedData: [categoryDataValue] = []
    
    var formatter : NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }
    
    var body: some View {
        Spacer()
        VStack(content: {
            
            VStack(alignment: .leading) {
                VStack(alignment: .leading, content: {
                    if data.isEmpty {
                        Text("\(getDataTypeName(for: identifier)!.uppercased())")
                        Text("No Data")
                            .bold()
                        Text("\(dateIntervalToString(from: startTime, to: endTime))")
                    }else {
                        if let date = selectedDate,
                           !selectedData.isEmpty {
                            Text("TOOTHBRUSHING")
                            let avgTime = totalTime(selectedData)
                            HStack {
                                let hr = Int(avgTime / 3600)
                                if hr > 0 {
                                    Text("\(hr)").bold() + Text(" hr")
                                }
                                let min = Int((avgTime % 3600)/60)
                                if min > 0 {
                                    Text("\(min)").bold() + Text(" min")
                                }
                                let sec = avgTime % 60
                                if sec > 0 {
                                    Text("\(sec)").bold() + Text(" sec")
                                }
                            }
                            
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                        } else {
                            Text("AVERAGE")
                            let avgTime = averageTime()
                            HStack {
                                let hr = Int(avgTime / 3600)
                                if hr > 0 {
                                    Text("\(hr)").bold() + Text(" hr")
                                }
                                let min = Int((avgTime % 3600)/60)
                                if min > 0 {
                                    Text("\(min)").bold() + Text(" min")
                                }
                                let sec = avgTime % 60
                                if sec > 0 {
                                    Text("\(sec)").bold() + Text(" sec")
                                }
                            }
                            Text("\(dateIntervalToString(from: startTime, to: endTime))")
                        }
                    }
                })
                Chart {
                    ForEach(data) { d in
                        BarMark(x: .value("Date", d.startDate, unit: .day),
                                y: .value("Time", intervalToTime(d.endDate.timeIntervalSince(d.startDate))))
                        .foregroundStyle(Calendar.current.isDateInToday(d.startDate) ? todayDataColor: pastDataColor)
                        .alignsMarkStylesWithPlotArea()
                        
                    }
                }
                .if(data.isEmpty) {view in
                    view.chartYScale(domain: 0...5)
                }
                .chartXScale(domain: startTime...endTime)
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: getVisibleDomain(start: startTime, end: endTime))
                .chartScrollPosition(initialX: max(startTime, beginningOfNextDay(endTime) - TimeInterval(7*dayInSec)))
                .chartScrollTargetBehavior(
                    .valueAligned(matching: DateComponents(hour: 0),
                                  majorAlignment: .matching(DateComponents(hour: 0, weekday: Calendar.current.component(.weekday, from: endTime) + 1)))
                )
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1))
                }
                .chartYAxis(content: {
                    
                    AxisMarks(values: .automatic, content: {
                        let value = $0.as(Double.self)!
                        AxisValueLabel {
                            Text("\(formatter.string(from: value as NSNumber) ?? "0") \(unit)")
                        }
                        AxisGridLine()
                    })
                })
                .chartOverlay(content: { proxy in
                    GeometryReader { geometry in
                        ZStack(alignment: .top, content: {
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .onTapGesture { location in
                                    updateSelectedDate(at: location, proxy: proxy, geometry: geometry)
                                }
                        })
                    }
                })
                .frame(maxHeight: UIScreen.main.bounds.size.width - 20)
            }
            .padding(.all, 10)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .clipped()
        })
        
        Spacer()
    }
    
    func updateSelectedDate(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let date: Date = proxy.value(atX:  xPosition) else {
            return
        }
        self.selectedData = []
        self.selectedDate = nil
        let selectedData = data.filter({Calendar.current.isDate($0.startDate, equalTo: date, toGranularity: .day)})
        self.selectedData = selectedData
        self.selectedDate = date
        
    }
    
    func intervalToTime(_ interval: TimeInterval) -> Double {
        if unit == "min" {
            return interval / 60
        } else {
            return interval / 3600
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
    
    func averageTime() -> Int {
        var total: Int = 0
        for d in data {
            total += Int(d.endDate.timeIntervalSince(d.startDate))
        }
        
        return total / data.count
    }
    
    func totalTime(_ data: [categoryDataValue]) -> Int {
        var sum = 0
        data.forEach({
            sum += Int($0.endDate.timeIntervalSince($0.startDate))
        })
        return sum
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
//#Preview {
//    CategorySingleValueChart()
//}

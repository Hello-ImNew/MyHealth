//
//  YearlyHealthChartView.swift
//  MyHealth
//
//  Created by Bao Bui on 3/22/24.
//

import SwiftUI
import Charts
import HealthKit

struct YearlyHealthChartView: View {
    let dayInSec = 24*3600
    let dataIdentifier: String
    let data:[quantityDataValue]
    let pastDataColor : LinearGradient = .linearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
    let todayDataColor : LinearGradient = .linearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
    var averageValue: Double {
        let values = data.map({$0.value})
        var sum = 0.0
        var count = 0.0
        for value in values {
            if value != 0 {
                sum += value
                count += 1
            }
        }
        return sum/count
    }
    
    var averageSecondValue: Double? {
        let values = data.compactMap({$0.secondaryValue})
        if values.isEmpty {
            return nil
        } else {
            var sum = 0.0
            var count = 0.0
            for value in values {
                if value != 0 {
                    sum += value
                    count += 1
                }
            }
            if count == 0 {
                return 0
            }
            return sum/count
        }
    }
    
    var formatter : NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }
    
    @State var selectedDate: Date?
    @State var selectedValue: Double?
    @State var selectedSecondValue: Double?
    
    var body: some View {
        VStack(alignment: .leading){
            VStack(alignment: .leading) {
                if let date = selectedDate,
                   let value = selectedValue
                {
                    Text("\(getStatisticsOptions(for: dataIdentifier) == HKStatisticsOptions.cumulativeSum ? "TOTAL" : "AVERAGE")")
                    Text("\(formatter.string(from: value as NSNumber) ?? "0.0")").bold()
                    + Text(selectedSecondValue != nil ? "/\(formatter.string(from: selectedSecondValue! as NSNumber) ?? "")" : "").bold()
                    + Text(" \(getUnit(for: dataIdentifier)!)")
                    Text(date.monthYear)
                } else {
                    Text("AVERAGE")
                    Text(formatter.string(from: averageValue as NSNumber) ?? "0.0").bold()
                    + Text(averageSecondValue != nil ? "/\(formatter.string(from: averageSecondValue! as NSNumber) ?? "")" : "").bold()
                    + Text(" \(getUnit(for: dataIdentifier)!)")
                    
                    Text(dateIntervalToString(from: data.first?.startDate, to: data.last?.endDate))
                }
            }
            Chart {
                ForEach(data) {d in
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: .month), y: .value("Value", d.secondaryValue ?? 0))
                        .foregroundStyle(.clear)
                }
                ForEach(data) {d in
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: .month), y: .value("Value", d.value - (d.secondaryValue ?? 0)))
                        .foregroundStyle(pastDataColor)
                        .alignsMarkStylesWithPlotArea()
                        .opacity(selectedDate != nil ? (Calendar.current.isDate(selectedDate!, equalTo: d.startDate, toGranularity: .month) ? 1 : 0.5) : 1)
                }
            }
            .if(data.isEmpty) {view in
                view.chartYScale(domain: 0...10)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 1)) {
                    let value = $0.as(Date.self)!
                    AxisValueLabel {
                        Text("\(getMonth(value))")
                    }
                    
                    AxisGridLine()
                }
            }
            .frame(width: 350, height: 300)
            .chartOverlay { proxy in
                
                GeometryReader { geometry in
                    ZStack(alignment: .top) {
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture {location in
                                updateSelectedDate(at: location, proxy: proxy, geometry: geometry)
                            }
//                            .gesture(DragGesture()
//                                .onChanged{value in
//                                updateSelectedDate(at: value.location, proxy: proxy, geometry: geometry)
//                            })
                    }
                }
            }
        }
        .padding(.all, 10 )
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .clipped()
    }
    
    func updateSelectedDate(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let date : Date = proxy.value(atX: xPosition) else {
            return
        }
        
        selectedDate = nil
        selectedValue = nil
        selectedSecondValue = nil
        
        let selectedData = data.first(where: { Calendar.current.isDate($0.startDate, equalTo: date, toGranularity: .month) })
        if selectedData?.value == 0 {
            return
        }
        selectedDate = date
        selectedValue = selectedData?.value
        selectedSecondValue = selectedData?.secondaryValue
        
    }
    
    func dateIntervalToString(from start: Date?, to end: Date?) -> String {
        guard let start = start,
              let end = end else {
            return ""
        }
        let calendar = Calendar.current
        if calendar.component(.year, from: start) == calendar.component(.year, from: end) {
            return "\(calendar.component(.year, from: start))"
        } else {
            return "\(start.monthYear ) - \(end.monthYear )"
        }
    }
    
    func getMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        return formatter.string(from: date)
    }
}


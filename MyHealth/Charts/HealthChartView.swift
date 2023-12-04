//
//  HealthChartView.swift
//  MyHealth
//
//  Created by Bao Bui on 10/3/23.
//

import Foundation
import HealthKit
import SwiftUI
import Charts

@available(iOS 17.0, *)
struct HealthChartView: View {
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
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                } else {
                    Text("DAILY AVERAGE")
                    Text(formatter.string(from: averageValue as NSNumber) ?? "0.0").bold()
                    + Text(averageSecondValue != nil ? "/\(formatter.string(from: averageSecondValue! as NSNumber) ?? "")" : "").bold()
                    + Text(" \(getUnit(for: dataIdentifier)!)")
                    
                    
                    
                    Text(dateIntervalToString(from: data.first?.startDate, to: data.last?.endDate))
                }
            }
            Chart {
                
                ForEach(data) {d in
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: .day), y: .value("Value", d.secondaryValue ?? 0))
                        .foregroundStyle(.clear)
                }
                ForEach(data) {d in
                    BarMark(x: .value(d.startDate.formatted(), d.startDate, unit: .day), y: .value("Value", d.value - (d.secondaryValue ?? 0)))
                        .foregroundStyle(Calendar.current.isDateInToday(d.startDate) ? todayDataColor : pastDataColor)
                        .alignsMarkStylesWithPlotArea()
                        .opacity(selectedDate != nil ? (Calendar.current.isDate(selectedDate!, equalTo: d.startDate, toGranularity: .day) ? 1 : 0.5) : 1)
                }
            }
            .chartXScale(domain: data.first!.startDate...data.last!.endDate)
            .frame(width: 350, height: 300)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: data.count <= 7 ? dayInSec*data.count : dayInSec*7)
            .chartScrollPosition(initialX: data.count > 7 ? data[data.count - 7].startDate : data[0].startDate)
            .chartYAxisLabel("\(getDataTypeName(for: dataIdentifier) ?? "") (\(getUnit(for: dataIdentifier) ?? ""))", position: .top, alignment: .center)
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
        
        selectedDate = date
        let selectedData = data.first(where: { Calendar.current.isDate($0.startDate, equalTo: date, toGranularity: .day) })
        selectedValue = selectedData?.value
        selectedSecondValue = selectedData?.secondaryValue
        
    }
    
    func dateIntervalToString(from start: Date?, to end: Date?) -> String {
        let dateIntervalFormatter = DateIntervalFormatter()
        dateIntervalFormatter.dateStyle = .medium
        dateIntervalFormatter.timeStyle = .none
        
        return dateIntervalFormatter.string(from: start!, to: end!)
    }
}

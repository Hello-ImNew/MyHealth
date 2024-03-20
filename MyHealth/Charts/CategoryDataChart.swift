//
//  CategoryDataChart.swift
//  MyHealth
//
//  Created by Bao Bui on 11/30/23.
//

import Foundation
import SwiftUI
import Charts
import HealthKit

@available(iOS 17.0, *)
struct CategoryDataChart: View {
    
    let dayInSec = 24*60*60
    var data: [categoryDataValue]
    var identifier: String
    var startTime: Date
    var endTime: Date
    
    @State var selectedDate: Date?
    @State var selectedData: [categoryDataValue]?
    @State var viewHeight: CGFloat = 0
    
    var body: some View {
        VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
            VStack(alignment: .leading) {
                HStack{
                    if let selectedData = selectedData,
                       let _ = selectedDate {
                        ForEach(selectedData) { element in
                            VStack(alignment: .leading) {
                                Text(getTitle(for: identifier))
                                Text("\(getCategoryValues(for: identifier)[element.value])").bold()
                                Text("\(dateIntervalToString(from: element.startDate, to: element.endDate))")
                            }
                        }
                    } else {
                        if data.count != 1 {
                            VStack(alignment: .leading){
                                Text("TOTAL")
                                Text("\(data.count) ").bold() + Text("entries")
                                Text("\(dateIntervalToString(from: startTime ,to: endTime))")
                            }
                        } else {
                            VStack(alignment: .leading) {
                                Text("SYMTOM")
                                Text("\(getCategoryValues(for: identifier)[data.first!.value])")
                                Text("\(dateIntervalToString(from: startTime, to: endTime))")
                            }
                        }
                    }
                }
                Chart {
                    ForEach(data) { datum in
                        RuleMark(xStart: .value("date", datum.startDate, unit: .minute),
                                 xEnd: .value("date", datum.endDate, unit: .minute),
                                 y: .value("value", getCategoryValues(for: datum.identifier)[datum.value]))
                        .lineStyle(StrokeStyle(lineWidth: 15, lineCap: .round))
                        .foregroundStyle(by: .value("Color", getCategoryValues(for: datum.identifier)[datum.value]))
                        
                        if let selectedDate = selectedDate,
                           let _ = selectedData {
                            RuleMark(x: .value("day", selectedDate))
                                .annotation(overflowResolution: .init(x: .fit(to: .chart))) {}
                                .opacity(0.1)
                                .foregroundStyle(Color(UIColor.lightGray))
                        }
                    }
                }
                .chartYScale(domain: getCategoryValues(for: identifier).reversed())
                .chartXScale(domain: startTime...beginningOfNextDay(endTime))
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: getVisibleDomain(start: startTime, end: endTime))
                .chartScrollPosition(initialX: max(startTime, beginningOfNextDay(endTime)-TimeInterval(7*dayInSec)))
                .chartScrollTargetBehavior(
                    .valueAligned(matching: DateComponents(hour: 0),
                                  majorAlignment: .matching(DateComponents(hour: 0, weekday: Calendar.current.component(.weekday, from: endTime) + 1))))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1))
                }
                .chartOverlay { proxy in
                    GeometryReader {geometry in
                        ZStack(alignment: .top) {
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .onTapGesture { location in
                                    updateSelectedTime(at: location, proxy: proxy, geometry: geometry)
                                }
                        }
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.size.width - 20)
            }
            .padding(.all, 10)
            .background(Color(uiColor: UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .clipped()
            .layoutPriority(999)
            
        }
    }
    
    func updateSelectedTime(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let date: Date = proxy.value(atX: xPosition) else {
            return
        }
        
        let selectedData: [categoryDataValue] = data.compactMap({element in
            if isDateInRange(dateToCheck: date, startDate: element.startDate, endDate: element.endDate) {
                return element
            } else {
                return nil
            }
        })
        
        self.selectedDate = nil
        self.selectedData = nil
        
        if selectedData.isEmpty {
            return
        }
        
        self.selectedDate = date
        self.selectedData = selectedData
    }
    
    func isDateInRange(dateToCheck: Date, startDate: Date, endDate: Date) -> Bool {
        return dateToCheck >= startDate && dateToCheck < endDate
    }
    
    
    
    func getVisibleDomain(start: Date, end: Date) -> Int {
        let end = beginningOfNextDay(end)
        let seconds = Int(end.timeIntervalSince(start))
        
        return min(seconds, 7*dayInSec)
    }
    
    func getTitle(for identifier: String) -> String {
        let categoryTypeIdentifier = HKCategoryTypeIdentifier(rawValue: identifier)
        switch categoryTypeIdentifier {
        case .abdominalCramps, .acne, .bladderIncontinence, .bloating, .breastPain, .chestTightnessOrPain, .chills, .constipation, .coughing, .diarrhea, .dizziness, .drySkin, .fainting, .fatigue, .fever, .generalizedBodyAche, .hairLoss, .headache, .heartburn, .hotFlashes, .lossOfSmell, .lossOfTaste, .lowerBackPain, .memoryLapse, .nausea, .nightSweats, .pelvicPain, .rapidPoundingOrFlutteringHeartbeat, .runnyNose, .shortnessOfBreath, .sinusCongestion, .skippedHeartbeat, .soreThroat, .vaginalDryness, .vomiting, .wheezing, .appetiteChanges, .sleepChanges, .moodChanges:
            return "SYMTOM"
        case .sleepAnalysis:
            return "Sleep Analysis"
        default:
            return ""
        }
    }
}

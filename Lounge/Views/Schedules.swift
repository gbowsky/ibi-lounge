//
//  Schedules.swift
//  LoungeApp
//
//  Created by g.gorbovskoy on 06.08.2023.
//

import SwiftUI

struct Schedules: View {
  @State var from: Date = .now;
  @State var to: Date = .now;
  var periodName: String?;
  var isEmbedded: Bool = false;
  var isCustomPeriod: Bool = false;
  @EnvironmentObject var settings: SettingsModel;
  @State var days: DaysRequestResult = .error(.loading);
  @State var range: ClosedRange<Date>? = Date()...Date();
  @State private var isShowingCalendar = false
  
  var content: any View {
    switch days {
    case .response(let result):
      ForEach(result.response!, id: \.self.date) { day in
        DayView(
          day: day
        )
      }
    case .error(let error):
      TransientStatusNew(error: error) {
        Task.init { await fetch() }
      }
    }
  }
  
  var body: some View {
    if isEmbedded {
      VStack {
        AnyView(content)
      }
      .task {
        await fetch()
      }
    } else {
      List {
        if isCustomPeriod {
          Section {
            HStack {
              Text("main.custom_range")
              Spacer()
              Button("\((range?.lowerBound.formatted(date: .numeric, time: .omitted)) ?? "???") - \((range?.upperBound.formatted(date: .numeric, time: .omitted)) ?? "???")") {
                withAnimation {
                  self.isShowingCalendar = true
                }
              }
            }
          }
        }
        AnyView(content)
      }
      .overlay {
        CalendarSheet(range: $range, isPresented: $isShowingCalendar)
          .onChange(of: range) { newValue in
            Task.init {
              await fetch();
            }
          }
      }
      .task {
        await fetch()
      }
      .refreshable {
        await fetch()
      }
      .navigationTitle(periodName != nil ? LocalizedStringKey(periodName!) : "Unknown period passed")
    }
  }
  
  func fetch() async {
    self.days = .error(.loading)
    
    if isCustomPeriod {
      if range != nil {
        days = await Requests().fetchSchedules(
          from: range!.lowerBound,
          to: range!.upperBound,
          group: settings.group
        )
      }
      return;
    }
    
    days = await Requests().fetchSchedules(
      from: from,
      to: to,
      group: settings.group
    )
  }
}

#Preview {
  Schedules()
    .environmentObject(SettingsModel())
}

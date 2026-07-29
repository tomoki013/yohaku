import SwiftUI

struct RootTabView: View {
    private enum Tab: Hashable {
        case today
        case week
        case month
    }

    @State private var selection: Tab = .today
    @State private var displayedDay = Date()
    @State private var displayedWeek = Date()
    @State private var displayedMonth = Date()

    // 今日タブ・週タブを再タップしたら現在に戻る
    private var tabSelection: Binding<Tab> {
        Binding(
            get: { selection },
            set: { newValue in
                if newValue == .today && selection == .today {
                    displayedDay = Date()
                } else if newValue == .week && selection == .week {
                    displayedWeek = Date()
                } else if newValue == .month && selection == .month {
                    displayedMonth = Date()
                }
                selection = newValue
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            TodayView(displayedDay: $displayedDay)
                .tabItem {
                    Label("tab.today", systemImage: "circle")
                }
                .tag(Tab.today)
            WeekView(displayedWeek: $displayedWeek) { day in
                displayedDay = day
                selection = .today
            }
            .tabItem {
                Label("tab.week", systemImage: "rectangle.split.3x1")
            }
            .tag(Tab.week)
            MonthView(displayedMonth: $displayedMonth) { day in
                displayedDay = day
                selection = .today
            }
                .tabItem {
                    Label("tab.month", systemImage: "calendar")
                }
                .tag(Tab.month)
        }
        .tint(.primary)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: YohakuBlock.self, inMemory: true)
}

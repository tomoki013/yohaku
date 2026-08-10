import SwiftUI
import SwiftData
import StoreKit

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Query private var blocks: [YohakuBlock]

    private enum Tab: Hashable {
        case today
        case week
        case month
    }

    @State private var selection: Tab = .today
    @State private var displayedDay = Date()
    @State private var displayedWeek = Date()
    @State private var displayedMonth = Date()
    @State private var launchCount = 0
    @State private var didRecordLaunch = false
    @State private var didPresentReflectionThisSession = false
    @State private var didRequestReviewThisSession = false

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
            TodayView(
                displayedDay: $displayedDay,
                isSelected: selection == .today,
                onReflectionPresented: {
                    didPresentReflectionThisSession = true
                }
            )
                .tabItem {
                    Label("tab.today", systemImage: "circle")
                }
                .tag(Tab.today)
            WeekView(
                displayedWeek: $displayedWeek,
                isSelected: selection == .week
            ) { day in
                displayedDay = day
                selection = .today
            }
            .tabItem {
                Label("tab.week", systemImage: "rectangle.split.3x1")
            }
            .tag(Tab.week)
            MonthView(
                displayedMonth: $displayedMonth,
                isSelected: selection == .month
            ) { day in
                displayedDay = day
                selection = .today
            }
                .tabItem {
                    Label("tab.month", systemImage: "calendar")
                }
                .tag(Tab.month)
        }
        .tint(.primary)
        .onAppear {
            guard !didRecordLaunch,
                  !ProcessInfo.processInfo.arguments.contains("-ScreenshotMode") else { return }
            didRecordLaunch = true
            launchCount = ReviewRequestTracker.recordLaunch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .yohakuBlockPlaced)) { _ in
            considerRequestingReview()
        }
        #if DEBUG
        .task {
            ScreenshotDemoSeeder.seedIfRequested(in: modelContext)
        }
        #endif
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1"
    }

    private func considerRequestingReview() {
        guard !didRequestReviewThisSession,
              !ProcessInfo.processInfo.arguments.contains("-ScreenshotMode") else { return }

        Task { @MainActor in
            // Let the creation sheet finish dismissing before the system sheet
            // is considered. Apple may still decide not to display it.
            try? await Task.sleep(for: .seconds(1.2))

            guard ReviewRequestPolicy.isEligible(
                blocks: blocks,
                now: Date(),
                launchCount: launchCount,
                lastRequestedVersion: ReviewRequestTracker.lastRequestedVersion,
                currentVersion: currentVersion,
                didPresentReflectionThisSession: didPresentReflectionThisSession
            ) else { return }

            didRequestReviewThisSession = true
            ReviewRequestTracker.markRequested(for: currentVersion)
            requestReview()
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: YohakuBlock.self, inMemory: true)
}

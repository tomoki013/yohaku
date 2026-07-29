import SwiftUI
import SwiftData

struct MonthView: View {
    @Query(sort: \YohakuBlock.startTime) private var blocks: [YohakuBlock]
    @Binding var displayedMonth: Date
    var onSelectDay: (Date) -> Void = { _ in }

    @State private var isShowingSettings = false
    @State private var slideDirection = 1

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var days: [Date] {
        DateHelpers.daysOfMonth(containing: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        let symbols = DateHelpers.calendar.veryShortStandaloneWeekdaySymbols
        let offset = DateHelpers.calendar.firstWeekday - 1
        return Array(symbols[offset...]) + Array(symbols[..<offset])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("tab.month")
                        .font(.title2)
                        .fontWeight(.medium)

                    monthSelector

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                            Text(symbol)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    monthGrid
                        .id(DateHelpers.calendar.dateInterval(of: .month, for: displayedMonth)?.start)
                        .transition(pageTransition)
                }
                .padding(24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        shiftMonth(by: value.translation.width < 0 ? 1 : -1)
                    }
            )
            .background(Color(.systemBackground))
            .toolbar {
                BrandToolbarItem()
                SettingsToolbarItem(isShowingSettings: $isShowingSettings)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }

    private var monthSelector: some View {
        HStack(spacing: 16) {
            monthButton(systemName: "chevron.backward", value: -1, label: "accessibility.previous_month")

            Text(displayedMonth, format: .dateTime.year().month(.wide))
                .font(.subheadline)
                .frame(maxWidth: .infinity)

            monthButton(systemName: "chevron.forward", value: 1, label: "accessibility.next_month")
        }
    }

    private func monthButton(
        systemName: String,
        value: Int,
        label: LocalizedStringKey
    ) -> some View {
        Button {
            shiftMonth(by: value)
        } label: {
            Image(systemName: systemName)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(Text(label))
    }

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<DateHelpers.leadingEmptyCount(forMonthContaining: displayedMonth), id: \.self) { _ in
                Color.clear
                    .frame(height: 52)
                    .accessibilityHidden(true)
            }

            ForEach(days, id: \.self) { day in
                dayCell(day)
            }
        }
        .animation(.easeInOut(duration: 0.24), value: displayedMonth)
    }

    private func dayCell(_ day: Date) -> some View {
        let dayBlocks = blocks.filter { DateHelpers.isSameDay($0.date, day) }
        let isToday = DateHelpers.isSameDay(day, Date())

        return Button {
            onSelectDay(day)
        } label: {
            VStack(spacing: 7) {
                Text(day, format: .dateTime.day())
                    .font(.subheadline)
                    .fontWeight(isToday ? .semibold : .regular)
                    .foregroundStyle(.primary)

                HStack(spacing: 3) {
                    ForEach(0..<min(dayBlocks.count, 3), id: \.self) { _ in
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if isToday {
                    Circle()
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                        .frame(width: 42, height: 42)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text(verbatim: String(
                format: NSLocalizedString(
                    dayBlocks.isEmpty ? "accessibility.day_no_yohaku %@" : "accessibility.day_has_yohaku %@",
                    comment: ""
                ),
                day.formatted(date: .long, time: .omitted)
            ))
        )
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: slideDirection > 0 ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: slideDirection > 0 ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func shiftMonth(by value: Int) {
        guard let shifted = DateHelpers.calendar.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }
        slideDirection = value
        withAnimation(.easeInOut(duration: 0.24)) {
            displayedMonth = shifted
        }
    }
}

#Preview {
    MonthView(displayedMonth: .constant(Date()))
        .modelContainer(for: YohakuBlock.self, inMemory: true)
}

import SwiftUI
import SwiftData

struct MonthView: View {
    @Query(sort: \YohakuBlock.startTime) private var blocks: [YohakuBlock]
    @Binding var displayedMonth: Date
    var isSelected = true
    var onSelectDay: (Date) -> Void = { _ in }

    @State private var isShowingSettings = false
    @State private var slideDirection = 1

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

    private var days: [Date] {
        DateHelpers.daysOfMonth(containing: displayedMonth)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("tab.month")
                        .font(.system(size: 36, weight: .semibold, design: .serif))

                    monthSelector

                    monthGrid
                        .id(DateHelpers.calendar.dateInterval(of: .month, for: displayedMonth)?.start)
                        .transition(pageTransition)

                    Divider()
                        .overlay(Color.primary.opacity(0.1))
                        .padding(.top, 8)

                    monthSummary
                }
                .padding(24)
                .padding(.bottom, 32)
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
            .yohakuBanner(
                isScreenEligible: isSelected,
                isModalPresented: isShowingSettings
            )
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
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<DateHelpers.leadingEmptyCount(forMonthContaining: displayedMonth), id: \.self) { _ in
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
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
            RoundedRectangle(cornerRadius: 2)
                .fill(dayBlocks.isEmpty ? Color.primary.opacity(0.055) : Color.primary)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.primary.opacity(0.55), lineWidth: 1.5)
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

    private var monthSummary: some View {
        let count = days.reduce(into: 0) { result, day in
            result += blocks.filter { DateHelpers.isSameDay($0.date, day) }.count
        }

        return VStack(alignment: .leading, spacing: 10) {
            Text("month.summary.title")
                .font(.title3)
                .fontWeight(.medium)
            Text(verbatim: String.localizedStringWithFormat(
                NSLocalizedString(
                    count == 0 ? "month.summary.empty" : "month.summary.count",
                    comment: ""
                ),
                count
            ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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

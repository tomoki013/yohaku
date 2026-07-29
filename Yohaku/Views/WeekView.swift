import SwiftUI
import SwiftData

struct WeekView: View {
    @Query(sort: \YohakuBlock.startTime) private var blocks: [YohakuBlock]
    @Binding var displayedWeek: Date
    var onSelectDay: (Date) -> Void = { _ in }
    @State private var isShowingSettings = false
    @State private var slideDirection = 1
    @State private var contentHeight: CGFloat?

    private var weekDays: [Date] {
        DateHelpers.daysOfWeek(containing: displayedWeek)
    }

    private var hasAnyBlockThisWeek: Bool {
        weekDays.contains { day in
            blocks.contains { DateHelpers.isSameDay($0.date, day) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("tab.week")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    weekSelector

                    // id を週にして差し替え、横スライドの遷移で滑らかに切り替える
                    ZStack(alignment: .top) {
                        weekContent
                            .id(weekDays.first)
                            .transition(pageTransition)
                            .measuringContentHeight()
                    }
                    .frame(height: contentHeight, alignment: .top)
                    .onPreferenceChange(ContentHeightPreferenceKey.self) { newHeight in
                        withAnimation(.easeOut(duration: 0.28)) {
                            contentHeight = newHeight
                        }
                    }
                }
                .padding(24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        if value.translation.width < -40 {
                            shiftWeek(by: 1)
                        } else if value.translation.width > 40 {
                            shiftWeek(by: -1)
                        }
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

    private var weekContent: some View {
        Group {
            if hasAnyBlockThisWeek {
                VStack(spacing: 0) {
                    ForEach(weekDays, id: \.self) { day in
                        dayRow(day)
                        if day != weekDays.last {
                            Divider()
                                .overlay(Color.primary.opacity(0.1))
                        }
                    }
                }
            } else {
                EmptyStateView(message: "empty.week")
            }
        }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: slideDirection > 0 ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: slideDirection > 0 ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var weekSelector: some View {
        HStack(spacing: 16) {
            Button {
                shiftWeek(by: -1)
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("accessibility.previous_week"))

            if let first = weekDays.first, let last = weekDays.last {
                HStack(spacing: 4) {
                    Text(first, format: .dateTime.month().day())
                    Text(verbatim: "–")
                    Text(last, format: .dateTime.month().day())
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }

            Button {
                shiftWeek(by: 1)
            } label: {
                Image(systemName: "chevron.forward")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("accessibility.next_week"))
        }
    }

    private func shiftWeek(by value: Int) {
        guard let shifted = Calendar.current.date(byAdding: .weekOfYear, value: value, to: displayedWeek) else { return }
        slideDirection = value
        withAnimation(.easeOut(duration: 0.28)) {
            displayedWeek = shifted
        }
    }

    private func dayRow(_ day: Date) -> some View {
        let dayBlocks = blocks.filter { DateHelpers.isSameDay($0.date, day) }
        let isToday = DateHelpers.isSameDay(day, Date())

        return Button {
            onSelectDay(day)
        } label: {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day, format: .dateTime.weekday(.abbreviated))
                        .font(.caption)
                        .foregroundStyle(isToday ? .primary : .secondary)
                    Text(day, format: .dateTime.day())
                        .font(.subheadline)
                        .fontWeight(isToday ? .semibold : .regular)
                        .foregroundStyle(isToday ? .primary : .secondary)
                }
                .frame(minWidth: 44, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(dayBlocks) { block in
                        HStack(spacing: 8) {
                            Capsule()
                                .fill(Color.primary)
                                .frame(width: 24, height: 4)
                            Text(block.title)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                            Text(block.startTime, format: .dateTime.hour().minute())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WeekView(displayedWeek: .constant(Date()))
        .modelContainer(for: YohakuBlock.self, inMemory: true)
}

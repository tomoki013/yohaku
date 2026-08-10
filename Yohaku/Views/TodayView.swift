import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \YohakuBlock.startTime) private var blocks: [YohakuBlock]
    @Binding var displayedDay: Date
    var isSelected = true
    var onReflectionPresented: () -> Void = {}
    @State private var isAdding = false
    @State private var isShowingSettings = false
    @State private var editing: YohakuBlock?
    @State private var releasing: YohakuBlock?
    @State private var slideDirection = 1
    @State private var contentHeight: CGFloat?
    @State private var activeReflectionID: UUID?

    private var dayBlocks: [YohakuBlock] {
        blocks.filter { DateHelpers.isSameDay($0.date, displayedDay) }
    }

    private var isToday: Bool {
        DateHelpers.isSameDay(displayedDay, Date())
    }

    private var activeReflection: YohakuBlock? {
        guard let activeReflectionID else { return nil }
        return blocks.first { $0.id == activeReflectionID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    pageHeader
                    daySelector

                    if isToday, let activeReflection {
                        ReflectionPromptCard(
                            block: activeReflection,
                            onRespond: { respond($0, to: activeReflection) },
                            onDismiss: dismissReflection
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // id を日付にして差し替え、横スライドの遷移で滑らかに切り替える
                    ZStack(alignment: .top) {
                        dayContent
                            .id(Calendar.current.startOfDay(for: displayedDay))
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
                .padding(.bottom, 72)
            }
            .scrollBounceBehavior(.basedOnSize)
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        if value.translation.width < -40 {
                            shiftDay(by: 1)
                        } else if value.translation.width > 40 {
                            shiftDay(by: -1)
                        }
                    }
            )
            .background(Color(.systemBackground))
            .overlay(alignment: .bottomTrailing) {
                addButton
                    .padding(.trailing, 24)
                    .padding(.bottom, 20)
            }
            .yohakuBanner(
                isScreenEligible: isSelected,
                isModalPresented: isAdding || isShowingSettings || editing != nil || releasing != nil
            )
            .toolbar {
                BrandToolbarItem()
                SettingsToolbarItem(isShowingSettings: $isShowingSettings)
            }
            .sheet(isPresented: $isAdding) {
                AddYohakuView(presetDate: displayedDay)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(item: $editing) { block in
                AddYohakuView(editing: block)
            }
            .confirmationDialog("confirm.release", isPresented: releaseBinding, titleVisibility: .visible) {
                Button("action.release", role: .destructive) {
                    if let block = releasing {
                        NotificationManager.cancel(id: block.id)
                        modelContext.delete(block)
                    }
                    releasing = nil
                }
                Button("action.close", role: .cancel) {
                    releasing = nil
                }
            }
            .onAppear(perform: prepareReflectionIfNeeded)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    prepareReflectionIfNeeded()
                }
            }
            .onChange(of: blocks.count) { _, _ in
                prepareReflectionIfNeeded()
            }
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("tab.today")
                .font(.system(size: 36, weight: .semibold, design: .serif))

            Text(displayedDay, format: .dateTime.year().month().day().weekday(.wide))
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var releaseBinding: Binding<Bool> {
        Binding(
            get: { releasing != nil },
            set: { if !$0 { releasing = nil } }
        )
    }

    private var dayContent: some View {
        Group {
            if dayBlocks.isEmpty {
                VStack(alignment: .leading, spacing: 20) {
                    EmptyStateView(message: isToday ? "empty.today" : "empty.day")
                }
            } else {
                VStack(spacing: 20) {
                    ForEach(dayBlocks) { block in
                        YohakuBlockCard(block: block)
                            .onTapGesture {
                                editing = block
                            }
                            .contextMenu {
                                Button {
                                    editing = block
                                } label: {
                                    Label("action.edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    releasing = block
                                } label: {
                                    Label("action.release", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: slideDirection > 0 ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: slideDirection > 0 ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var addButton: some View {
        Button {
            isAdding = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.regular))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 60, height: 60)
                .background(Color.primary, in: Circle())
                .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("add.title"))
        .accessibilityIdentifier("add-button")
    }

    private var daySelector: some View {
        HStack(spacing: 16) {
            Button {
                shiftDay(by: -1)
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("accessibility.previous_day"))

            Text(displayedDay, format: .dateTime.month().day().weekday())
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            Button {
                shiftDay(by: 1)
            } label: {
                Image(systemName: "chevron.forward")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("accessibility.next_day"))
        }
    }

    private func shiftDay(by value: Int) {
        guard let shifted = Calendar.current.date(byAdding: .day, value: value, to: displayedDay) else { return }
        slideDirection = value
        withAnimation(.easeOut(duration: 0.28)) {
            displayedDay = shifted
        }
    }

    private func prepareReflectionIfNeeded() {
        guard activeReflectionID == nil,
              !(ProcessInfo.processInfo.arguments.contains("-ScreenshotMode")
                && !ProcessInfo.processInfo.arguments.contains("-ReflectionPreview")) else { return }

        let candidates = YohakuReflectionPolicy.unpresentedEndedBlocks(from: blocks, now: Date())
        guard let latest = candidates.first else { return }

        // Only the most recent ended space is shown. Older ones are quietly
        // acknowledged so opening the app never becomes a backlog of prompts.
        let presentedAt = Date()
        candidates.forEach { $0.reflectionPresentedAt = presentedAt }
        try? modelContext.save()

        withAnimation(.easeOut(duration: 0.25)) {
            activeReflectionID = latest.id
        }
        onReflectionPresented()
    }

    private func respond(_ response: YohakuReflectionResponse, to block: YohakuBlock) {
        block.reflectionResponseRawValue = response.rawValue
        block.reflectionRespondedAt = Date()
        try? modelContext.save()
        dismissReflection()
    }

    private func dismissReflection() {
        withAnimation(.easeOut(duration: 0.2)) {
            activeReflectionID = nil
        }
    }
}

#Preview {
    TodayView(displayedDay: .constant(Date()))
        .modelContainer(for: YohakuBlock.self, inMemory: true)
        .environment(SupportPurchaseStore())
        .environment(AdConsentManager())
}

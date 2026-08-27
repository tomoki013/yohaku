import SwiftUI
import SwiftData

struct AddYohakuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    private let editingBlock: YohakuBlock?

    @State private var title: String
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isConfirmingRelease = false
    @State private var nameSuggestions: [String]

    private static let namePoolKeys = (1...10).map { "name.pool.\($0)" }

    init(editing block: YohakuBlock? = nil, presetDate: Date? = nil) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let requestedDay = calendar.startOfDay(for: presetDate ?? Date())
        let initialDate = block?.date ?? max(today, requestedDay)
        let initialStart = block?.startTime ?? Self.nextQuarterHour(after: Date())

        editingBlock = block
        _title = State(initialValue: block?.title ?? "")
        _date = State(initialValue: initialDate)
        _startTime = State(initialValue: initialStart)
        _endTime = State(initialValue: block?.endTime ?? initialStart.addingTimeInterval(3600))
        // 先頭は定番の「何もしない時間」で固定、残りはシャッフル
        _nameSuggestions = State(initialValue: block == nil
            ? ([Self.namePoolKeys[0]] + Self.namePoolKeys.dropFirst().shuffled())
                .map { NSLocalizedString($0, comment: "") }
            : [])
    }

    private var canPlace: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedStartTime < selectedEndTime
            && (editingBlock != nil || selectedStartTime > Date())
    }

    private var hasPastStartTime: Bool {
        editingBlock == nil && selectedStartTime <= Date()
    }

    private var selectedStartTime: Date {
        time(startTime, on: date)
    }

    private var selectedEndTime: Date {
        time(endTime, on: date)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TextField("field.name", text: $title)
                    .font(.title3)
                    .fontWeight(.medium)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .padding(.vertical, 14)

                hairline

                if !nameSuggestions.isEmpty && title.isEmpty {
                    suggestionChips
                }

                VStack(spacing: 0) {
                    fieldRow("field.date") {
                        if editingBlock == nil {
                            DatePicker(
                                "field.date",
                                selection: $date,
                                in: Calendar.current.startOfDay(for: Date())...,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                        } else {
                            DatePicker("field.date", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                    hairline
                    fieldRow("field.start") {
                        DatePicker("field.start", selection: $startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    hairline
                    fieldRow("field.end") {
                        DatePicker("field.end", selection: $endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }

                if hasPastStartTime {
                    Text("validation.future_time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                }

                Spacer(minLength: 24)

                Button(action: place) {
                    Text(editingBlock == nil ? "action.place" : "action.save")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(Color.primary.opacity(canPlace ? 1 : 0.35)))
                }
                .disabled(!canPlace)
                .animation(.easeInOut(duration: 0.15), value: canPlace)

                if editingBlock != nil {
                    Button {
                        isConfirmingRelease = true
                    } label: {
                        Text("action.release")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 16)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 20)
            .background(Color(.systemBackground))
            .navigationTitle(editingBlock == nil ? "add.title" : "edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.medium))
                    }
                    .accessibilityLabel(Text("action.close"))
                    .accessibilityIdentifier("close-button")
                }
            }
        }
        // No banner on this sheet. A bottom safe-area inset inside a sheet
        // pushes the place/save button out of the card's visible area, and the
        // keyboard toggling the banner made it appear and vanish while typing.
        // The presenting tab already hides its own banner while this is up.
        .tint(.primary)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .confirmationDialog("confirm.release", isPresented: $isConfirmingRelease, titleVisibility: .visible) {
            Button("action.release", role: .destructive) {
                if let block = editingBlock {
                    NotificationManager.cancel(id: block.id)
                    modelContext.delete(block)
                }
                dismiss()
            }
            Button("action.close", role: .cancel) {}
        }
        .onAppear {
            if editingBlock == nil {
                isNameFocused = true
            }
        }
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(nameSuggestions.enumerated()), id: \.element) { index, name in
                    Button {
                        title = name
                    } label: {
                        Text(verbatim: name)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(
                                Capsule()
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("suggestion-\(index)")
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 1)
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(height: 1)
    }

    private func fieldRow(_ label: LocalizedStringKey, @ViewBuilder control: () -> some View) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            control()
        }
        .padding(.vertical, 8)
    }

    private func place() {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let placedStartTime = time(startTime, on: day)
        let placedEndTime = time(endTime, on: day)

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let block = editingBlock {
            block.title = trimmedTitle
            block.date = day
            block.startTime = placedStartTime
            block.endTime = placedEndTime
            block.updatedAt = Date()
            NotificationManager.schedule(for: block)
        } else {
            let block = YohakuBlock(
                title: trimmedTitle,
                date: day,
                startTime: placedStartTime,
                endTime: placedEndTime
            )
            modelContext.insert(block)
            try? modelContext.save()
            NotificationManager.requestInitialAuthorizationIfNeeded { granted in
                if granted {
                    NotificationManager.schedule(for: block)
                }
            }
            NotificationCenter.default.post(name: .yohakuBlockPlaced, object: nil)
        }
        dismiss()
    }

    private func time(_ time: Date, on day: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: calendar.startOfDay(for: day)
        ) ?? calendar.startOfDay(for: day)
    }

    private static func nextQuarterHour(after date: Date) -> Date {
        let calendar = Calendar.current
        let startOfMinute = calendar.dateInterval(of: .minute, for: date)?.start ?? date
        let minute = calendar.component(.minute, from: startOfMinute)
        let minutesToAdd = 15 - (minute % 15)
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: startOfMinute)
            ?? date.addingTimeInterval(15 * 60)
    }
}

#Preview {
    AddYohakuView()
        .modelContainer(for: YohakuBlock.self, inMemory: true)
}

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
        editingBlock = block
        _title = State(initialValue: block?.title ?? "")
        _date = State(initialValue: block?.date ?? presetDate ?? Date())
        _startTime = State(initialValue: block?.startTime ?? Date())
        _endTime = State(initialValue: block?.endTime ?? Date().addingTimeInterval(3600))
        // 先頭は定番の「何もしない時間」で固定、残りはシャッフル
        _nameSuggestions = State(initialValue: block == nil
            ? ([Self.namePoolKeys[0]] + Self.namePoolKeys.dropFirst().shuffled())
                .map { NSLocalizedString($0, comment: "") }
            : [])
    }

    private var canPlace: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && startTime < endTime
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
                        DatePicker("field.date", selection: $date, displayedComponents: .date)
                            .labelsHidden()
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
                }
            }
        }
        .yohakuBanner()
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
                ForEach(nameSuggestions, id: \.self) { name in
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

        func onSelectedDay(_ time: Date) -> Date {
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(
                bySettingHour: components.hour ?? 0,
                minute: components.minute ?? 0,
                second: 0,
                of: day
            ) ?? day
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let block = editingBlock {
            block.title = trimmedTitle
            block.date = day
            block.startTime = onSelectedDay(startTime)
            block.endTime = onSelectedDay(endTime)
            block.updatedAt = Date()
            NotificationManager.schedule(for: block)
        } else {
            let block = YohakuBlock(
                title: trimmedTitle,
                date: day,
                startTime: onSelectedDay(startTime),
                endTime: onSelectedDay(endTime)
            )
            modelContext.insert(block)
            NotificationManager.requestInitialAuthorizationIfNeeded { granted in
                if granted {
                    NotificationManager.schedule(for: block)
                }
            }
        }
        dismiss()
    }
}

#Preview {
    AddYohakuView()
        .modelContainer(for: YohakuBlock.self, inMemory: true)
}

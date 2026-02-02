import SwiftUI

struct AddHealthEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let horses: [Horse]

    @State private var selectedHorse: Horse?
    @State private var eventType: HealthEventType = .farrier
    @State private var date: Date = .now
    @State private var notes = ""
    @State private var providerName = ""
    @State private var cost: Double?
    @State private var autoCalculateNextDue = true
    @State private var customNextDueDate: Date = .now
    @State private var hasAttemptedSave = false

    /// Collect previously used provider names for auto-suggest.
    private var knownProviders: [String] {
        let all = horses.flatMap(\.healthEvents)
            .compactMap(\.providerName)
            .filter { !$0.isEmpty }
        return Array(Set(all)).sorted()
    }

    /// Auto-select the single horse if only one is provided (quick-log from feed board).
    init(horses: [Horse]) {
        self.horses = horses
        if horses.count == 1 {
            _selectedHorse = State(initialValue: horses.first)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if horses.count > 1 {
                    Section("Horse") {
                        Picker("Select Horse", selection: $selectedHorse) {
                            Text("Choose...").tag(nil as Horse?)
                            ForEach(horses) { horse in
                                Text(horse.name).tag(horse as Horse?)
                            }
                        }
                    }
                } else if let horse = horses.first {
                    Section("Horse") {
                        HStack {
                            Text(horse.name)
                                .font(EquineFont.headline)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.pastureGreen)
                        }
                    }
                }

                Section("Event Details") {
                    Picker("Type", selection: $eventType) {
                        ForEach(HealthEventType.allCases) { type in
                            Label(type.rawValue, systemImage: type.iconName).tag(type)
                        }
                    }

                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)

                    // Provider with auto-suggest
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Provider Name", text: $providerName)
                        if !knownProviders.isEmpty && providerName.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(knownProviders, id: \.self) { provider in
                                        Button(provider) {
                                            providerName = provider
                                            HapticManager.selection()
                                        }
                                        .font(EquineFont.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.parchment)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Cost ($)", value: $cost, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                        if hasAttemptedSave, let msg = FormValidation.validateCost(cost).message {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(Color.alertRed)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Details or observations...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Next Due Date") {
                    Toggle("Auto-calculate", isOn: $autoCalculateNextDue)
                        .tint(.hunterGreen)

                    if autoCalculateNextDue {
                        if let suggested = HealthEvent.suggestedNextDueDate(for: eventType, from: date) {
                            HStack {
                                Text("Suggested")
                                Spacer()
                                Text(suggested, style: .date)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(eventType.defaultCycleDescription)
                            .font(EquineFont.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        DatePicker("Custom Date", selection: $customNextDueDate, in: date..., displayedComponents: .date)
                        if hasAttemptedSave,
                           let msg = FormValidation.validateEventDates(eventDate: date, nextDueDate: customNextDueDate).message {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(Color.alertRed)
                        }
                    }
                }
            }
            .navigationTitle("Log Health Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { attemptSave() }
                        .disabled(selectedHorse == nil)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func attemptSave() {
        hasAttemptedSave = true
        guard let horse = selectedHorse else { return }

        let costValid = FormValidation.validateCost(cost)
        let datesValid = autoCalculateNextDue
            ? FormValidation.Result.valid
            : FormValidation.validateEventDates(eventDate: date, nextDueDate: customNextDueDate)

        guard costValid.isValid && datesValid.isValid else {
            HapticManager.notification(.error)
            return
        }

        let nextDue: Date?
        if autoCalculateNextDue {
            nextDue = HealthEvent.suggestedNextDueDate(for: eventType, from: date)
        } else {
            nextDue = customNextDueDate
        }

        let event = HealthEvent(
            type: eventType,
            date: date,
            notes: notes,
            nextDueDate: nextDue,
            cost: cost,
            providerName: providerName.isEmpty ? nil : providerName
        )

        horse.healthEvents.append(event)
        HapticManager.notification(.success)
        dismiss()
    }
}

#Preview {
    AddHealthEventView(horses: [PreviewContainer.sampleHorse()])
        .modelContainer(PreviewContainer.shared.container)
}

import SwiftUI

struct AddHealthEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let horses: [Horse]
    let existingEvent: HealthEvent?
    let existingEventHorse: Horse?

    @State private var selectedHorse: Horse?
    @State private var eventType: HealthEventType = .farrier
    @State private var date: Date = .now
    @State private var notes = ""
    @State private var providerName = ""
    @State private var cost: Double?
    @State private var autoCalculateNextDue = true
    @State private var customNextDueDate: Date = .now
    @State private var hasAttemptedSave = false
    @State private var costFieldTouched = false
    @State private var isSaving = false
    @State private var showSuccessToast = false

    private var isEditing: Bool { existingEvent != nil }

    /// Collect previously used provider names for auto-suggest.
    private var knownProviders: [String] {
        let all = horses.flatMap(\.healthEvents)
            .compactMap(\.providerName)
            .filter { !$0.isEmpty }
        return Array(Set(all)).sorted()
    }

    /// Auto-select the single horse if only one is provided (quick-log from feed board).
    init(horses: [Horse], existingEvent: HealthEvent? = nil, horse: Horse? = nil) {
        self.horses = horses
        self.existingEvent = existingEvent
        self.existingEventHorse = horse

        if let event = existingEvent {
            // Editing mode - pre-fill all fields
            _eventType = State(initialValue: event.type)
            _date = State(initialValue: event.date)
            _notes = State(initialValue: event.notes)
            _providerName = State(initialValue: event.providerName ?? "")
            _cost = State(initialValue: event.cost)
            _selectedHorse = State(initialValue: horse)

            if let nextDue = event.nextDueDate {
                let suggested = HealthEvent.suggestedNextDueDate(for: event.type, from: event.date)
                if let suggested, Calendar.current.isDate(nextDue, inSameDayAs: suggested) {
                    _autoCalculateNextDue = State(initialValue: true)
                } else {
                    _autoCalculateNextDue = State(initialValue: false)
                    _customNextDueDate = State(initialValue: nextDue)
                }
            } else {
                _autoCalculateNextDue = State(initialValue: true)
            }
        } else if horses.count == 1 {
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
                        HStack {
                            TextField("Cost", value: $cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .keyboardType(.decimalPad)
                                .onChange(of: cost) { _, newValue in
                                    if !costFieldTouched && newValue != nil {
                                        costFieldTouched = true
                                    }
                                }

                            if costFieldTouched || hasAttemptedSave {
                                let validation = FormValidation.validateCost(cost)
                                Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundStyle(validation.isValid ? Color.pastureGreen : Color.alertRed)
                                    .font(.body)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: FormValidation.validateCost(cost).isValid)

                        if (costFieldTouched || hasAttemptedSave), let msg = FormValidation.validateCost(cost).message {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(Color.alertRed)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.15), value: FormValidation.validateCost(cost).message != nil)
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
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Suggested Next Due")
                                        .font(EquineFont.caption)
                                        .foregroundStyle(.secondary)
                                    Text(suggested, style: .date)
                                        .font(EquineFont.headline)
                                        .foregroundStyle(Color.hunterGreen)
                                }
                                Spacer()
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color.hunterGreen)
                                    .symbolEffect(.pulse, options: .repeating.speed(0.5))
                            }
                            .padding(.vertical, 4)
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
            .navigationTitle(isEditing ? "Edit Health Event" : "Log Health Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        attemptSave()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(Color.hunterGreen)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(selectedHorse == nil || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .toast(isShowing: $showSuccessToast, message: isEditing ? "Event updated!" : "Event logged!", icon: "checkmark.circle.fill", color: .pastureGreen)
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

        isSaving = true

        let nextDue: Date?
        if autoCalculateNextDue {
            nextDue = HealthEvent.suggestedNextDueDate(for: eventType, from: date)
        } else {
            nextDue = customNextDueDate
        }

        if let existingEvent {
            // Update existing event
            existingEvent.type = eventType
            existingEvent.date = date
            existingEvent.notes = notes
            existingEvent.nextDueDate = nextDue
            existingEvent.cost = cost
            existingEvent.providerName = providerName.isEmpty ? nil : providerName
        } else {
            // Create new event
            let event = HealthEvent(
                type: eventType,
                date: date,
                notes: notes,
                nextDueDate: nextDue,
                cost: cost,
                providerName: providerName.isEmpty ? nil : providerName
            )
            horse.healthEvents.append(event)
        }

        HapticManager.notification(.success)

        withAnimation {
            showSuccessToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}

#Preview {
    AddHealthEventView(horses: [PreviewContainer.sampleHorse()])
        .modelContainer(PreviewContainer.shared.container)
}

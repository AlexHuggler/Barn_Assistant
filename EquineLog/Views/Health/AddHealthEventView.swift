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

    var body: some View {
        NavigationStack {
            Form {
                Section("Horse") {
                    Picker("Select Horse", selection: $selectedHorse) {
                        Text("Choose...").tag(nil as Horse?)
                        ForEach(horses) { horse in
                            Text(horse.name).tag(horse as Horse?)
                        }
                    }
                }

                Section("Event Details") {
                    Picker("Type", selection: $eventType) {
                        ForEach(HealthEventType.allCases) { type in
                            Label(type.rawValue, systemImage: type.iconName).tag(type)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    TextField("Provider Name", text: $providerName)
                    TextField("Cost ($)", value: $cost, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
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
                        DatePicker("Custom Date", selection: $customNextDueDate, displayedComponents: .date)
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
                    Button("Save") { saveEvent() }
                        .disabled(selectedHorse == nil)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveEvent() {
        guard let horse = selectedHorse else { return }

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
        dismiss()
    }
}

#Preview {
    AddHealthEventView(horses: [PreviewContainer.sampleHorse()])
        .modelContainer(PreviewContainer.shared.container)
}

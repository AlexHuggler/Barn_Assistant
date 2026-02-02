import SwiftUI

struct EditFeedScheduleView: View {
    @Bindable var horse: Horse
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amGrain: String
    @State private var amHay: String
    @State private var amSupplementsText: String
    @State private var amMedicationsText: String
    @State private var pmGrain: String
    @State private var pmHay: String
    @State private var pmSupplementsText: String
    @State private var pmMedicationsText: String
    @State private var specialInstructions: String

    init(horse: Horse) {
        self.horse = horse
        let schedule = horse.feedSchedule
        _amGrain = State(initialValue: schedule?.amGrain ?? "")
        _amHay = State(initialValue: schedule?.amHay ?? "")
        _amSupplementsText = State(initialValue: schedule?.amSupplements.joined(separator: ", ") ?? "")
        _amMedicationsText = State(initialValue: schedule?.amMedications.joined(separator: ", ") ?? "")
        _pmGrain = State(initialValue: schedule?.pmGrain ?? "")
        _pmHay = State(initialValue: schedule?.pmHay ?? "")
        _pmSupplementsText = State(initialValue: schedule?.pmSupplements.joined(separator: ", ") ?? "")
        _pmMedicationsText = State(initialValue: schedule?.pmMedications.joined(separator: ", ") ?? "")
        _specialInstructions = State(initialValue: schedule?.specialInstructions ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("AM Feed") {
                    TextField("Grain (e.g., 2 qt SafeChoice)", text: $amGrain)
                    TextField("Hay (e.g., 2 flakes Timothy)", text: $amHay)
                    TextField("Supplements (comma-separated)", text: $amSupplementsText)
                    TextField("Medications (comma-separated)", text: $amMedicationsText)
                }

                Section("PM Feed") {
                    TextField("Grain", text: $pmGrain)
                    TextField("Hay", text: $pmHay)
                    TextField("Supplements (comma-separated)", text: $pmSupplementsText)
                    TextField("Medications (comma-separated)", text: $pmMedicationsText)
                }

                Section("Special Instructions") {
                    TextField("Notes for barn staff...", text: $specialInstructions, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Feed Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let parse: (String) -> [String] = { text in
            text.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }

        if let schedule = horse.feedSchedule {
            schedule.amGrain = amGrain
            schedule.amHay = amHay
            schedule.amSupplements = parse(amSupplementsText)
            schedule.amMedications = parse(amMedicationsText)
            schedule.pmGrain = pmGrain
            schedule.pmHay = pmHay
            schedule.pmSupplements = parse(pmSupplementsText)
            schedule.pmMedications = parse(pmMedicationsText)
            schedule.specialInstructions = specialInstructions
        } else {
            let schedule = FeedSchedule(
                amGrain: amGrain,
                amHay: amHay,
                amSupplements: parse(amSupplementsText),
                amMedications: parse(amMedicationsText),
                pmGrain: pmGrain,
                pmHay: pmHay,
                pmSupplements: parse(pmSupplementsText),
                pmMedications: parse(pmMedicationsText),
                specialInstructions: specialInstructions
            )
            horse.feedSchedule = schedule
        }

        dismiss()
    }
}

#Preview {
    EditFeedScheduleView(horse: PreviewContainer.sampleHorse())
        .modelContainer(PreviewContainer.shared.container)
}

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
    @State private var isSaving = false
    @State private var showSuccessToast = false
    @State private var showingSaveAsTemplate = false
    @State private var templateName = ""
    @State private var templateDescription = ""
    @State private var showTemplateToast = false

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

                Section {
                    Button {
                        showingSaveAsTemplate = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .foregroundStyle(Color.hunterGreen)
                            Text("Save as Template")
                                .foregroundStyle(Color.barnText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Save this feed schedule as a reusable template for future horses.")
                }
            }
            .navigationTitle("Edit Feed Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(Color.hunterGreen)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving)
                    .fontWeight(.semibold)
                }
            }
            .toast(isShowing: $showSuccessToast, message: "Schedule saved!", icon: "checkmark.circle.fill", color: .pastureGreen)
            .toast(isShowing: $showTemplateToast, message: "Template created!", icon: "doc.badge.plus", color: .hunterGreen)
            .alert("Save as Template", isPresented: $showingSaveAsTemplate) {
                TextField("Template name", text: $templateName)
                TextField("Description (optional)", text: $templateDescription)
                Button("Cancel", role: .cancel) {
                    templateName = ""
                    templateDescription = ""
                }
                Button("Save") {
                    saveAsTemplate()
                }
                .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("Give this template a name so you can apply it to other horses later.")
            }
        }
    }

    private func save() {
        isSaving = true

        if let schedule = horse.feedSchedule {
            schedule.amGrain = amGrain
            schedule.amHay = amHay
            schedule.amSupplements = StringUtilities.parseCSV(amSupplementsText)
            schedule.amMedications = StringUtilities.parseCSV(amMedicationsText)
            schedule.pmGrain = pmGrain
            schedule.pmHay = pmHay
            schedule.pmSupplements = StringUtilities.parseCSV(pmSupplementsText)
            schedule.pmMedications = StringUtilities.parseCSV(pmMedicationsText)
            schedule.specialInstructions = specialInstructions
        } else {
            let schedule = FeedSchedule(
                amGrain: amGrain,
                amHay: amHay,
                amSupplements: StringUtilities.parseCSV(amSupplementsText),
                amMedications: StringUtilities.parseCSV(amMedicationsText),
                pmGrain: pmGrain,
                pmHay: pmHay,
                pmSupplements: StringUtilities.parseCSV(pmSupplementsText),
                pmMedications: StringUtilities.parseCSV(pmMedicationsText),
                specialInstructions: specialInstructions
            )
            horse.feedSchedule = schedule
        }

        HapticManager.notification(.success)

        withAnimation {
            showSuccessToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }

    private func saveAsTemplate() {
        let template = FeedTemplate(
            name: templateName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: templateDescription,
            amGrain: amGrain,
            amHay: amHay,
            amSupplements: StringUtilities.parseCSV(amSupplementsText),
            amMedications: StringUtilities.parseCSV(amMedicationsText),
            pmGrain: pmGrain,
            pmHay: pmHay,
            pmSupplements: StringUtilities.parseCSV(pmSupplementsText),
            pmMedications: StringUtilities.parseCSV(pmMedicationsText),
            specialInstructions: specialInstructions
        )

        modelContext.insert(template)
        HapticManager.notification(.success)

        // Reset fields
        templateName = ""
        templateDescription = ""

        withAnimation {
            showTemplateToast = true
        }
    }
}

#Preview {
    EditFeedScheduleView(horse: PreviewContainer.sampleHorse())
        .modelContainer(PreviewContainer.shared.container)
}

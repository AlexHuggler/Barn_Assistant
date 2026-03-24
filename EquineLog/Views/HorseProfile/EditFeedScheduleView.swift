import SwiftUI

struct EditFeedScheduleView: View {
    @Bindable var horse: Horse
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amGrain: String
    @State private var amHay: String
    @State private var amSupplements: [String]
    @State private var amMedications: [String]
    @State private var pmGrain: String
    @State private var pmHay: String
    @State private var pmSupplements: [String]
    @State private var pmMedications: [String]
    @State private var specialInstructions: String
    @State private var isSaving = false
    @State private var showSuccessToast = false
    @State private var showingSaveAsTemplate = false
    @State private var templateName = ""
    @State private var templateDescription = ""
    @State private var showTemplateToast = false

    // Keyboard navigation
    enum Field: Hashable {
        case amGrain, amHay, amSupplements, amMedications
        case pmGrain, pmHay, pmSupplements, pmMedications
        case specialInstructions
    }
    @FocusState private var focusedField: Field?

    private static let fieldOrder: [Field] = [
        .amGrain, .amHay, .amSupplements, .amMedications,
        .pmGrain, .pmHay, .pmSupplements, .pmMedications,
        .specialInstructions
    ]

    init(horse: Horse) {
        self.horse = horse
        let schedule = horse.feedSchedule
        _amGrain = State(initialValue: schedule?.amGrain ?? "")
        _amHay = State(initialValue: schedule?.amHay ?? "")
        _amSupplements = State(initialValue: schedule?.amSupplements ?? [])
        _amMedications = State(initialValue: schedule?.amMedications ?? [])
        _pmGrain = State(initialValue: schedule?.pmGrain ?? "")
        _pmHay = State(initialValue: schedule?.pmHay ?? "")
        _pmSupplements = State(initialValue: schedule?.pmSupplements ?? [])
        _pmMedications = State(initialValue: schedule?.pmMedications ?? [])
        _specialInstructions = State(initialValue: schedule?.specialInstructions ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("AM Feed") {
                    TextField("Grain (e.g., 2 qt SafeChoice)", text: $amGrain)
                        .focused($focusedField, equals: .amGrain)
                    TextField("Hay (e.g., 2 flakes Timothy)", text: $amHay)
                        .focused($focusedField, equals: .amHay)
                    ChipInputView(label: "Add supplement…", chips: $amSupplements, isFocused: focusedField == .amSupplements, onCommitFocus: { focusedField = .amMedications })
                    ChipInputView(label: "Add medication…", chips: $amMedications, isFocused: focusedField == .amMedications, onCommitFocus: { focusedField = .pmGrain })
                }

                Section("PM Feed") {
                    if hasAMFeedData {
                        Button {
                            copyAMtoPM()
                            HapticManager.selection()
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                    .foregroundStyle(Color.hunterGreen)
                                Text("Copy AM Feed to PM")
                                    .foregroundStyle(Color.barnText)
                                Spacer()
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(Color.hunterGreen)
                            }
                            .font(EquineFont.caption)
                        }
                        .accessibilityHint("Copies all AM feed fields into PM feed fields")
                    }
                    TextField("Grain", text: $pmGrain)
                        .focused($focusedField, equals: .pmGrain)
                    TextField("Hay", text: $pmHay)
                        .focused($focusedField, equals: .pmHay)
                    ChipInputView(label: "Add supplement…", chips: $pmSupplements, isFocused: focusedField == .pmSupplements, onCommitFocus: { focusedField = .pmMedications })
                    ChipInputView(label: "Add medication…", chips: $pmMedications, isFocused: focusedField == .pmMedications, onCommitFocus: { focusedField = .specialInstructions })
                }

                Section("Special Instructions") {
                    TextField("Notes for barn staff...", text: $specialInstructions, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($focusedField, equals: .specialInstructions)
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
            .keyboardNav(focusedField: $focusedField, fields: Self.fieldOrder)
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

    private var hasAMFeedData: Bool {
        !amGrain.isEmpty || !amHay.isEmpty || !amSupplements.isEmpty || !amMedications.isEmpty
    }

    private func copyAMtoPM() {
        pmGrain = amGrain
        pmHay = amHay
        pmSupplements = amSupplements
        pmMedications = amMedications
    }

    private func save() {
        isSaving = true

        if let schedule = horse.feedSchedule {
            schedule.amGrain = amGrain
            schedule.amHay = amHay
            schedule.amSupplements = amSupplements
            schedule.amMedications = amMedications
            schedule.pmGrain = pmGrain
            schedule.pmHay = pmHay
            schedule.pmSupplements = pmSupplements
            schedule.pmMedications = pmMedications
            schedule.specialInstructions = specialInstructions
        } else {
            let schedule = FeedSchedule(
                amGrain: amGrain,
                amHay: amHay,
                amSupplements: amSupplements,
                amMedications: amMedications,
                pmGrain: pmGrain,
                pmHay: pmHay,
                pmSupplements: pmSupplements,
                pmMedications: pmMedications,
                specialInstructions: specialInstructions
            )
            horse.feedSchedule = schedule
        }

        HapticManager.successSequence()

        withAnimation {
            showSuccessToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + ViewConstants.feedbackDelay) {
            dismiss()
        }
    }

    private func saveAsTemplate() {
        let template = FeedTemplate(
            name: templateName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: templateDescription,
            amGrain: amGrain,
            amHay: amHay,
            amSupplements: amSupplements,
            amMedications: amMedications,
            pmGrain: pmGrain,
            pmHay: pmHay,
            pmSupplements: pmSupplements,
            pmMedications: pmMedications,
            specialInstructions: specialInstructions
        )

        modelContext.insert(template)
        HapticManager.successSequence()

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

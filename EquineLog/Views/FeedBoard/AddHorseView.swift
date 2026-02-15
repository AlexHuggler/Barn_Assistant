import SwiftUI
import PhotosUI
import SwiftData

struct AddHorseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingHorses: [Horse]

    // Horse fields
    @State private var name = ""
    @State private var ownerName = ""
    @State private var isClipped = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?

    // Feed schedule fields
    @State private var amGrain = ""
    @State private var amHay = ""
    @State private var amSupplementsText = ""
    @State private var amMedicationsText = ""
    @State private var pmGrain = ""
    @State private var pmHay = ""
    @State private var pmSupplementsText = ""
    @State private var pmMedicationsText = ""
    @State private var specialInstructions = ""

    // Smart defaults
    @State private var copyFromHorse: Horse?

    // Validation
    @State private var hasAttemptedSave = false

    var body: some View {
        NavigationStack {
            Form {
                horseDetailsSection
                coatStatusSection
                smartDefaultsSection
                amFeedSection
                pmFeedSection
                instructionsSection
            }
            .navigationTitle("Add Horse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { attemptSave() }
                        .disabled(!isFormValid)
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                loadPhoto(from: newValue)
            }
            .onChange(of: copyFromHorse) { _, horse in
                if let horse { applyDefaults(from: horse) }
            }
        }
    }

    // MARK: - Validation

    private var nameValidation: FormValidation.Result {
        FormValidation.validateHorseName(name)
    }

    private var ownerValidation: FormValidation.Result {
        FormValidation.validateOwnerName(ownerName)
    }

    private var isFormValid: Bool {
        nameValidation.isValid && ownerValidation.isValid
    }

    // MARK: - Form Sections

    private var horseDetailsSection: some View {
        Section("Horse Details") {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Name", text: $name)
                    .font(EquineFont.body)
                    .autocorrectionDisabled()
                if hasAttemptedSave, let msg = nameValidation.message {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(Color.alertRed)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Owner Name", text: $ownerName)
                    .font(EquineFont.body)
                if hasAttemptedSave, let msg = ownerValidation.message {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(Color.alertRed)
                }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack {
                    Text("Photo")
                    Spacer()
                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "camera.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.hunterGreen)
                    }
                }
            }
        }
    }

    private var coatStatusSection: some View {
        Section("Coat Status") {
            Toggle("Clipped (Shorn)", isOn: $isClipped)
                .tint(.hunterGreen)

            Text(isClipped
                 ? "Clipped horses need blankets at higher temperatures."
                 : "Unclipped horses retain natural insulation.")
                .font(EquineFont.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var smartDefaultsSection: some View {
        if !existingHorses.isEmpty {
            Section("Quick Fill") {
                Picker("Copy feed schedule from", selection: $copyFromHorse) {
                    Text("None").tag(nil as Horse?)
                    ForEach(existingHorses) { horse in
                        Text(horse.name).tag(horse as Horse?)
                    }
                }

                Text("Pre-fills the feed schedule from an existing horse. You can edit after copying.")
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var amFeedSection: some View {
        Section("AM Feed") {
            TextField("Grain (e.g., 2 qt SafeChoice)", text: $amGrain)
            TextField("Hay (e.g., 2 flakes Timothy)", text: $amHay)
            TextField("Supplements (comma-separated)", text: $amSupplementsText)
            TextField("Medications (comma-separated)", text: $amMedicationsText)
        }
    }

    private var pmFeedSection: some View {
        Section("PM Feed") {
            TextField("Grain", text: $pmGrain)
            TextField("Hay", text: $pmHay)
            TextField("Supplements (comma-separated)", text: $pmSupplementsText)
            TextField("Medications (comma-separated)", text: $pmMedicationsText)
        }
    }

    private var instructionsSection: some View {
        Section("Special Instructions") {
            TextField("e.g., Soaked hay only, muzzle on turnout", text: $specialInstructions, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    // MARK: - Actions

    private func attemptSave() {
        hasAttemptedSave = true
        guard isFormValid else {
            HapticManager.notification(.error)
            return
        }
        commitHorse()
    }

    private func commitHorse() {
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

        let horse = Horse(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            ownerName: ownerName.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: imageData,
            isClipped: isClipped,
            feedSchedule: schedule
        )

        modelContext.insert(horse)
        HapticManager.notification(.success)
        dismiss()
    }

    private func applyDefaults(from horse: Horse) {
        guard let schedule = horse.feedSchedule else { return }
        amGrain = schedule.amGrain
        amHay = schedule.amHay
        amSupplementsText = schedule.amSupplements.joined(separator: ", ")
        amMedicationsText = schedule.amMedications.joined(separator: ", ")
        pmGrain = schedule.pmGrain
        pmHay = schedule.pmHay
        pmSupplementsText = schedule.pmSupplements.joined(separator: ", ")
        pmMedicationsText = schedule.pmMedications.joined(separator: ", ")
        specialInstructions = schedule.specialInstructions
        // Pre-fill owner name if the same owner manages multiple horses
        if ownerName.isEmpty {
            ownerName = horse.ownerName
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                imageData = data
            }
        }
    }
}

#Preview {
    AddHorseView()
        .modelContainer(PreviewContainer.shared.container)
}

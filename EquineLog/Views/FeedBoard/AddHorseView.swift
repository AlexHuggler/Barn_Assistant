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
    @State private var nameFieldTouched = false
    @State private var ownerFieldTouched = false

    // Photo loading state
    @State private var isLoadingPhoto = false
    @State private var photoLoadingError: String?

    // Save state
    @State private var isSaving = false
    @State private var showSuccessToast = false

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
                    .disabled(!isFormValid || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                loadPhoto(from: newValue)
            }
            .onChange(of: copyFromHorse) { _, horse in
                if let horse { applyDefaults(from: horse) }
            }
            .toast(isShowing: $showSuccessToast, message: "\(name) added!", icon: "checkmark.circle.fill", color: .pastureGreen)
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
                HStack {
                    TextField("Name", text: $name)
                        .font(EquineFont.body)
                        .autocorrectionDisabled()
                        .onChange(of: name) { _, _ in
                            if !nameFieldTouched && !name.isEmpty {
                                nameFieldTouched = true
                            }
                        }

                    // Real-time validation indicator
                    if nameFieldTouched || hasAttemptedSave {
                        Image(systemName: nameValidation.isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(nameValidation.isValid ? Color.pastureGreen : Color.alertRed)
                            .font(.body)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: nameValidation.isValid)

                if (nameFieldTouched || hasAttemptedSave), let msg = nameValidation.message {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(Color.alertRed)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: nameValidation.message != nil)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField("Owner Name", text: $ownerName)
                        .font(EquineFont.body)
                        .onChange(of: ownerName) { _, _ in
                            if !ownerFieldTouched && !ownerName.isEmpty {
                                ownerFieldTouched = true
                            }
                        }

                    if ownerFieldTouched || hasAttemptedSave {
                        Image(systemName: ownerValidation.isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(ownerValidation.isValid ? Color.pastureGreen : Color.alertRed)
                            .font(.body)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: ownerValidation.isValid)

                if (ownerFieldTouched || hasAttemptedSave), let msg = ownerValidation.message {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(Color.alertRed)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: ownerValidation.message != nil)

            VStack(alignment: .leading, spacing: 4) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Text("Photo")
                        Spacer()
                        if isLoadingPhoto {
                            ProgressView()
                                .frame(width: 44, height: 44)
                        } else if let imageData, let uiImage = UIImage(data: imageData) {
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

                if let error = photoLoadingError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.alertRed)
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
        isSaving = true

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

        // Show toast briefly before dismissing
        withAnimation {
            showSuccessToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
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

        // Clear previous error
        photoLoadingError = nil
        isLoadingPhoto = true

        Task {
            do {
                let data = try await item.loadTransferable(type: Data.self)
                await MainActor.run {
                    if let data, UIImage(data: data) != nil {
                        imageData = data
                    } else {
                        photoLoadingError = "Unable to load image. Please try a different photo."
                        HapticManager.notification(.error)
                    }
                    isLoadingPhoto = false
                }
            } catch {
                await MainActor.run {
                    photoLoadingError = "Photo loading failed: \(error.localizedDescription)"
                    isLoadingPhoto = false
                    HapticManager.notification(.error)
                }
            }
        }
    }
}

#Preview {
    AddHorseView()
        .modelContainer(PreviewContainer.shared.container)
}

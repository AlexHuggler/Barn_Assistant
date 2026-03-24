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
    @State private var amSupplements: [String] = []
    @State private var amMedications: [String] = []
    @State private var pmGrain = ""
    @State private var pmHay = ""
    @State private var pmSupplements: [String] = []
    @State private var pmMedications: [String] = []
    @State private var specialInstructions = ""

    // Smart defaults
    @State private var copyFromHorse: Horse?
    @State private var showingTemplateLibrary = false

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

    // Keyboard navigation
    enum Field: Hashable {
        case name, ownerName
        case amGrain, amHay, amSupplements, amMedications
        case pmGrain, pmHay, pmSupplements, pmMedications
        case specialInstructions
    }
    @FocusState private var focusedField: Field?

    private static let fieldOrder: [Field] = [
        .name, .ownerName,
        .amGrain, .amHay, .amSupplements, .amMedications,
        .pmGrain, .pmHay, .pmSupplements, .pmMedications,
        .specialInstructions
    ]

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
            .keyboardNav(focusedField: $focusedField, fields: Self.fieldOrder)
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
            .sheet(isPresented: $showingTemplateLibrary) {
                FeedTemplateLibraryView { template in
                    applyTemplate(template)
                }
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

    private var suggestedAmGrain: String? {
        SmartDefaults.mostCommon(existingHorses.compactMap(\.feedSchedule?.amGrain))
    }

    private var suggestedAmHay: String? {
        SmartDefaults.mostCommon(existingHorses.compactMap(\.feedSchedule?.amHay))
    }

    // MARK: - Form Sections

    private var horseDetailsSection: some View {
        Section("Horse Details") {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField("Name", text: $name)
                        .font(EquineFont.body)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .onChange(of: name) { _, _ in
                            if !nameFieldTouched && !name.isEmpty {
                                nameFieldTouched = true
                            }
                        }

                    ValidationIndicatorView(validation: nameValidation, isVisible: nameFieldTouched || hasAttemptedSave)
                }
                .animation(.easeInOut(duration: 0.2), value: nameValidation.isValid)

                ValidationMessageView(validation: nameValidation, isVisible: nameFieldTouched || hasAttemptedSave)
            }
            .animation(.easeInOut(duration: 0.15), value: nameValidation.message != nil)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField("Owner Name", text: $ownerName)
                        .font(EquineFont.body)
                        .focused($focusedField, equals: .ownerName)
                        .onChange(of: ownerName) { _, _ in
                            if !ownerFieldTouched && !ownerName.isEmpty {
                                ownerFieldTouched = true
                            }
                        }

                    ValidationIndicatorView(validation: ownerValidation, isVisible: ownerFieldTouched || hasAttemptedSave)
                }
                .animation(.easeInOut(duration: 0.2), value: ownerValidation.isValid)

                ValidationMessageView(validation: ownerValidation, isVisible: ownerFieldTouched || hasAttemptedSave)
            }
            .animation(.easeInOut(duration: 0.15), value: ownerValidation.message != nil)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
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

                    if imageData != nil {
                        Button {
                            imageData = nil
                            selectedPhoto = nil
                            HapticManager.impact(.light)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.alertRed.opacity(0.7))
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove photo")
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

    private var smartDefaultsSection: some View {
        Section("Quick Fill") {
            Button {
                showingTemplateLibrary = true
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundStyle(Color.hunterGreen)
                    Text("Apply Feed Template")
                        .foregroundStyle(Color.barnText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityHint("Opens template library to apply a saved feed schedule")

            if !existingHorses.isEmpty {
                Picker("Copy from horse", selection: $copyFromHorse) {
                    Text("None").tag(nil as Horse?)
                    ForEach(existingHorses) { horse in
                        Text(horse.name).tag(horse as Horse?)
                    }
                }
            }

            Text("Use templates or copy from an existing horse to quickly fill the feed schedule.")
                .font(EquineFont.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var amFeedSection: some View {
        Section("AM Feed") {
            TextField("Grain", text: $amGrain, prompt: Text(suggestedAmGrain ?? "e.g., 2 qt SafeChoice").foregroundStyle(.tertiary))
                .focused($focusedField, equals: .amGrain)
            TextField("Hay", text: $amHay, prompt: Text(suggestedAmHay ?? "e.g., 2 flakes Timothy").foregroundStyle(.tertiary))
                .focused($focusedField, equals: .amHay)
            ChipInputView(label: "Add supplement…", chips: $amSupplements, isFocused: focusedField == .amSupplements, onCommitFocus: { focusedField = .amMedications })
            ChipInputView(label: "Add medication…", chips: $amMedications, isFocused: focusedField == .amMedications, onCommitFocus: { focusedField = .pmGrain })
        }
    }

    private var pmFeedSection: some View {
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

    private var instructionsSection: some View {
        Section("Special Instructions") {
            TextField("e.g., Soaked hay only, muzzle on turnout", text: $specialInstructions, axis: .vertical)
                .lineLimit(2...4)
                .focused($focusedField, equals: .specialInstructions)
        }
    }

    // MARK: - Actions

    private func attemptSave() {
        hasAttemptedSave = true
        guard isFormValid else {
            HapticManager.warningSequence()
            return
        }
        commitHorse()
    }

    private func commitHorse() {
        isSaving = true

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

        let horse = Horse(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            ownerName: ownerName.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: imageData,
            isClipped: isClipped,
            feedSchedule: schedule
        )

        modelContext.insert(horse)
        HapticManager.successSequence()

        // Show toast briefly before dismissing
        withAnimation {
            showSuccessToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + ViewConstants.feedbackDelay) {
            dismiss()
        }
    }

    private func applyDefaults(from horse: Horse) {
        guard let schedule = horse.feedSchedule else { return }
        amGrain = schedule.amGrain
        amHay = schedule.amHay
        amSupplements = schedule.amSupplements
        amMedications = schedule.amMedications
        pmGrain = schedule.pmGrain
        pmHay = schedule.pmHay
        pmSupplements = schedule.pmSupplements
        pmMedications = schedule.pmMedications
        specialInstructions = schedule.specialInstructions
        // Pre-fill owner name if the same owner manages multiple horses
        if ownerName.isEmpty {
            ownerName = horse.ownerName
        }
    }

    private func applyTemplate(_ template: FeedTemplate) {
        amGrain = template.amGrain
        amHay = template.amHay
        amSupplements = template.amSupplements
        amMedications = template.amMedications
        pmGrain = template.pmGrain
        pmHay = template.pmHay
        pmSupplements = template.pmSupplements
        pmMedications = template.pmMedications
        specialInstructions = template.specialInstructions
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
                        HapticManager.warningSequence()
                    }
                    isLoadingPhoto = false
                }
            } catch {
                await MainActor.run {
                    photoLoadingError = "Photo loading failed: \(error.localizedDescription)"
                    isLoadingPhoto = false
                    HapticManager.warningSequence()
                }
            }
        }
    }
}

#Preview {
    AddHorseView()
        .modelContainer(PreviewContainer.shared.container)
}

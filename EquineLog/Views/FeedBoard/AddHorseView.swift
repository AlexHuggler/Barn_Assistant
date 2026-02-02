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

    // Paywall
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                horseDetailsSection
                coatStatusSection
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
                    Button("Save") { saveHorse() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                loadPhoto(from: newValue)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Form Sections

    private var horseDetailsSection: some View {
        Section("Horse Details") {
            TextField("Name", text: $name)
                .font(EquineFont.body)
            TextField("Owner Name", text: $ownerName)
                .font(EquineFont.body)

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

    private func saveHorse() {
        // Paywall check: if 1+ horse already exists, show paywall
        if existingHorses.count >= 1 {
            showPaywall = true
            return
        }

        commitHorse()
    }

    func commitHorse() {
        let schedule = FeedSchedule(
            amGrain: amGrain,
            amHay: amHay,
            amSupplements: parseCSV(amSupplementsText),
            amMedications: parseCSV(amMedicationsText),
            pmGrain: pmGrain,
            pmHay: pmHay,
            pmSupplements: parseCSV(pmSupplementsText),
            pmMedications: parseCSV(pmMedicationsText),
            specialInstructions: specialInstructions
        )

        let horse = Horse(
            name: name,
            ownerName: ownerName,
            imageData: imageData,
            isClipped: isClipped,
            feedSchedule: schedule
        )

        modelContext.insert(horse)
        dismiss()
    }

    private func parseCSV(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
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

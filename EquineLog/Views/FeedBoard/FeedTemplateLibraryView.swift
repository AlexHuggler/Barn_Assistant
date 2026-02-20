import SwiftUI
import SwiftData

struct FeedTemplateLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FeedTemplate.usageCount, order: .reverse) private var templates: [FeedTemplate]

    let onSelect: (FeedTemplate) -> Void

    @State private var showingCreateTemplate = false
    @State private var templateToDelete: FeedTemplate?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Feed Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateTemplate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.hunterGreen)
                    }
                    .accessibilityLabel("Create new template")
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateFeedTemplateView()
            }
            .confirmationDialog(
                "Delete Template",
                isPresented: $showingDeleteConfirmation,
                presenting: templateToDelete
            ) { template in
                Button("Delete \"\(template.name)\"", role: .destructive) {
                    deleteTemplate(template)
                }
            } message: { template in
                Text("Are you sure you want to delete this template? This cannot be undone.")
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Templates", systemImage: "doc.badge.plus")
        } description: {
            Text("Create templates to quickly apply feed schedules to new horses.")
        } actions: {
            Button {
                showingCreateTemplate = true
            } label: {
                Text("Create Template")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var templateList: some View {
        List {
            Section {
                Text("Tap a template to apply it. Templates save time when adding horses with similar feed requirements.")
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section("Your Templates") {
                ForEach(templates) { template in
                    TemplateRow(template: template)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            applyTemplate(template)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                templateToDelete = template
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Actions

    private func applyTemplate(_ template: FeedTemplate) {
        template.recordUsage()
        HapticManager.impact(.medium)
        onSelect(template)
        dismiss()
    }

    private func deleteTemplate(_ template: FeedTemplate) {
        modelContext.delete(template)
        HapticManager.notification(.success)
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: FeedTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(template.name)
                    .font(EquineFont.headline)
                    .foregroundStyle(Color.barnText)

                Spacer()

                if template.usageCount > 0 {
                    Text("Used \(template.usageCount)×")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !template.templateDescription.isEmpty {
                Text(template.templateDescription)
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(template.summary)
                .font(EquineFont.feedBoard)
                .foregroundStyle(Color.hunterGreen)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.name). \(template.summary)")
        .accessibilityHint("Tap to apply this template")
    }
}

// MARK: - Create Template View

struct CreateFeedTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var templateDescription = ""
    @State private var amGrain = ""
    @State private var amHay = ""
    @State private var amSupplementsText = ""
    @State private var amMedicationsText = ""
    @State private var pmGrain = ""
    @State private var pmHay = ""
    @State private var pmSupplementsText = ""
    @State private var pmMedicationsText = ""
    @State private var specialInstructions = ""
    @State private var isSaving = false
    @State private var showSuccessToast = false

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Info") {
                    TextField("Template Name", text: $name)
                        .font(EquineFont.body)
                    TextField("Description (optional)", text: $templateDescription)
                        .font(EquineFont.body)
                }

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
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveTemplate()
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
            .toast(isShowing: $showSuccessToast, message: "Template created!", icon: "checkmark.circle.fill", color: .pastureGreen)
        }
    }

    private func saveTemplate() {
        isSaving = true

        let template = FeedTemplate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
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

        withAnimation {
            showSuccessToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}

#Preview {
    FeedTemplateLibraryView { _ in }
        .modelContainer(PreviewContainer.shared.container)
}

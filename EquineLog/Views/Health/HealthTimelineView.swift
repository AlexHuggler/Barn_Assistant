import SwiftUI
import SwiftData

struct HealthTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Horse.name) private var horses: [Horse]
    @State private var viewModel = HealthTimelineViewModel()
    @State private var eventToDelete: HealthEvent?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if horses.isEmpty {
                    emptyState
                } else {
                    timelineContent
                }
            }
            .navigationTitle("Maintenance")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !horses.isEmpty {
                        Button {
                            viewModel.showingAddEvent = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.hunterGreen)
                        }
                        .accessibilityLabel("Add health event")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddEvent) {
                AddHealthEventView(horses: horses)
            }
            .sheet(isPresented: $viewModel.showingEditEvent) {
                if let event = viewModel.eventToEdit {
                    AddHealthEventView(
                        horses: horses,
                        existingEvent: event,
                        horse: viewModel.eventToEditHorse
                    )
                }
            }
            .confirmationDialog(
                "Delete Event",
                isPresented: $showingDeleteConfirmation,
                presenting: eventToDelete
            ) { event in
                Button("Delete", role: .destructive) {
                    modelContext.delete(event)
                    HapticManager.successSequence()
                }
            } message: { event in
                Text("Are you sure you want to delete this \(event.type.rawValue.lowercased()) event? This cannot be undone.")
            }
        }
    }

    // MARK: - Subviews

    private var timelineContent: some View {
        List {
            // Filter chips section
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    // Event type filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "All", isSelected: viewModel.selectedFilter == nil, selectedColor: .hunterGreen) {
                                viewModel.selectedFilter = nil
                            }
                            ForEach(HealthEventType.allCases) { type in
                                FilterChip(title: type.rawValue, isSelected: viewModel.selectedFilter == type, selectedColor: .hunterGreen, icon: type.iconName) {
                                    viewModel.selectedFilter = type
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }

                    // Horse filter
                    if horses.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                FilterChip(title: "All Horses", isSelected: viewModel.selectedHorse == nil, selectedColor: .saddleBrown) {
                                    viewModel.selectedHorse = nil
                                }
                                ForEach(horses) { horse in
                                    FilterChip(title: horse.name, isSelected: viewModel.selectedHorse?.id == horse.id, selectedColor: .saddleBrown) {
                                        viewModel.selectedHorse = horse
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }

            // Event groups
            let groups = viewModel.upcomingEvents(from: horses)
            if groups.isEmpty {
                Section {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.pastureGreen.opacity(0.6))
                            .symbolEffect(.breathe, options: .repeating.speed(0.3))
                        Text("All Caught Up")
                            .font(EquineFont.title)
                            .foregroundStyle(Color.barnText)
                        Text("No upcoming maintenance events.\nAll health records are up to date.")
                            .font(EquineFont.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { item in
                            HealthEventRow(item: item, isOverdue: group.isOverdue)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.eventToEdit = item.event
                                    viewModel.eventToEditHorse = item.horse
                                    viewModel.showingEditEvent = true
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        eventToDelete = item.event
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        viewModel.eventToEdit = item.event
                                        viewModel.eventToEditHorse = item.horse
                                        viewModel.showingEditEvent = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(Color.hunterGreen)
                                }
                        }
                    } header: {
                        HStack {
                            Text(group.title)
                                .font(EquineFont.caption)
                                .foregroundStyle(group.isOverdue ? Color.alertRed : Color.barnText)
                            StatusBadge(text: "\(group.items.count)", color: group.isOverdue ? .alertRed : .hunterGreen)
                            if group.isOverdue {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.alertRed)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.selectedFilter = viewModel.selectedFilter
            HapticManager.impact(.light)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 64))
                .foregroundStyle(Color.saddleBrown.opacity(0.5))
                .symbolEffect(.breathe, options: .repeating.speed(0.3))
            Text("No Horses Added")
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)
            Text("Add horses from the Stable tab\nto track health events.")
                .font(EquineFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Health Event Row

struct HealthEventRow: View {
    let item: HealthEventItem
    let isOverdue: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.event.type.iconName)
                .font(.title3)
                .foregroundStyle(isOverdue ? Color.alertRed : Color.hunterGreen)
                .frame(width: 36, height: 36)
                .background(
                    (isOverdue ? Color.alertRed : Color.hunterGreen).opacity(0.1)
                )
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.event.type.rawValue)
                        .font(EquineFont.headline)
                        .foregroundStyle(isOverdue ? Color.alertRed : Color.barnText)
                    Text("- \(item.horseName)")
                        .font(EquineFont.body)
                        .foregroundStyle(.secondary)
                }

                Text(item.event.formattedDueStatus)
                    .font(EquineFont.caption)
                    .foregroundStyle(isOverdue ? Color.alertRed : .secondary)

                if let dueDate = item.event.nextDueDate {
                    Text(dueDate, style: .date)
                        .font(EquineFont.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if isOverdue {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Color.alertRed)
                    .accessibilityHidden(true)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Tap to edit this event")
    }

    private var accessibilityDescription: String {
        var description = "\(item.event.type.rawValue) for \(item.horseName). \(item.event.formattedDueStatus)"
        if isOverdue {
            description = "Overdue: " + description
        }
        return description
    }
}

#Preview {
    HealthTimelineView()
        .modelContainer(PreviewContainer.shared.container)
}

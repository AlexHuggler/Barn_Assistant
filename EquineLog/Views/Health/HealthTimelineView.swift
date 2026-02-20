import SwiftUI
import SwiftData

struct HealthTimelineView: View {
    @Query(sort: \Horse.name) private var horses: [Horse]
    @State private var viewModel = HealthTimelineViewModel()

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
                            filterChip(title: "All", type: nil)
                            ForEach(HealthEventType.allCases) { type in
                                filterChip(title: type.rawValue, type: type)
                            }
                        }
                        .padding(.horizontal, 2)
                    }

                    // Horse filter
                    if horses.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                horseFilterChip(title: "All Horses", horse: nil)
                                ForEach(horses) { horse in
                                    horseFilterChip(title: horse.name, horse: horse)
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
                    ContentUnavailableView(
                        "No Upcoming Events",
                        systemImage: "calendar.badge.checkmark",
                        description: Text("All maintenance is up to date.")
                    )
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
                        }
                    } header: {
                        HStack {
                            Text(group.title)
                                .font(EquineFont.caption)
                                .foregroundStyle(group.isOverdue ? Color.alertRed : Color.barnText)
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
    }

    private func filterChip(title: String, type: HealthEventType?) -> some View {
        let isSelected = viewModel.selectedFilter == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedFilter = type
            }
        } label: {
            Text(title)
                .font(EquineFont.caption)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.hunterGreen : Color.parchment)
                .foregroundStyle(isSelected ? .white : Color.barnText)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func horseFilterChip(title: String, horse: Horse?) -> some View {
        let isSelected = viewModel.selectedHorse?.id == horse?.id
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedHorse = horse
            }
        } label: {
            HStack(spacing: 6) {
                if let horse {
                    HorseAvatarView(horse: horse, size: 20)
                }
                Text(title)
                    .font(EquineFont.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.saddleBrown : Color.parchment)
            .foregroundStyle(isSelected ? .white : Color.barnText)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Horses Added",
            systemImage: "heart.text.clipboard",
            description: Text("Add horses from the Stable tab to track health events.")
        )
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

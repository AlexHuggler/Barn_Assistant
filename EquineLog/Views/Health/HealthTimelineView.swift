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
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddEvent) {
                AddHealthEventView(horses: horses)
            }
        }
    }

    // MARK: - Subviews

    private var timelineContent: some View {
        List {
            // Filter chips
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        filterChip(title: "All", type: nil)
                        ForEach(HealthEventType.allCases) { type in
                            filterChip(title: type.rawValue, type: type)
                        }
                    }
                    .padding(.horizontal, 2)
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
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HealthTimelineView()
        .modelContainer(PreviewContainer.shared.container)
}

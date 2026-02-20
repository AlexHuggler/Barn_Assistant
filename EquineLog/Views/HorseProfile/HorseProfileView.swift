import SwiftUI
import SwiftData

struct HorseProfileView: View {
    @Bindable var horse: Horse
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddEvent = false
    @State private var showingEditFeed = false
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    @State private var showingAnalytics = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                feedScheduleCard
                quickStatsCard
                healthHistoryCard
                actionsCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(horse.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddEvent = true
                    } label: {
                        Label("Log Health Event", systemImage: "heart.text.clipboard")
                    }
                    Button {
                        showingEditFeed = true
                    } label: {
                        Label("Edit Feed Schedule", systemImage: "pencil")
                    }
                    Divider()
                    Button {
                        generateAndShareReport()
                    } label: {
                        Label("Generate Owner Report", systemImage: "doc.richtext")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.hunterGreen)
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddHealthEventView(horses: [horse])
        }
        .sheet(isPresented: $showingEditFeed) {
            EditFeedScheduleView(horse: horse)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData {
                ShareSheet(items: [pdfData])
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsDashboardView(horse: horse)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            HorseAvatarView(horse: horse, size: 100)
                .overlay(Circle().stroke(Color.hunterGreen, lineWidth: 3))

            VStack(spacing: 4) {
                Text(horse.name)
                    .font(EquineFont.largeTitle)
                    .foregroundStyle(Color.barnText)
                Text("Owner: \(horse.ownerName)")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    StatusBadge(
                        text: horse.isClipped ? "Clipped" : "Unclipped",
                        color: horse.isClipped ? .saddleBrown : .hunterGreen
                    )
                    if !horse.overdueEvents.isEmpty {
                        StatusBadge(text: "\(horse.overdueEvents.count) Overdue", color: .alertRed)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .equineCard()
    }

    // MARK: - Feed Schedule Card

    private var feedScheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Feed Schedule", systemImage: "cup.and.saucer.fill")
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)

            if let schedule = horse.feedSchedule {
                VStack(alignment: .leading, spacing: 8) {
                    feedSlotRow(label: "AM", summary: schedule.amSummary,
                                supplements: schedule.amSupplements,
                                medications: schedule.amMedications)
                    Divider()
                    feedSlotRow(label: "PM", summary: schedule.pmSummary,
                                supplements: schedule.pmSupplements,
                                medications: schedule.pmMedications)

                    if !schedule.specialInstructions.isEmpty {
                        Divider()
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.saddleBrown)
                            Text(schedule.specialInstructions)
                                .font(EquineFont.caption)
                                .foregroundStyle(Color.saddleBrown)
                        }
                    }
                }
            } else {
                Button("Set Up Feed Schedule") {
                    showingEditFeed = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .equineCard()
    }

    private func feedSlotRow(label: String, summary: String, supplements: [String], medications: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(EquineFont.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.hunterGreen)
                    .clipShape(Capsule())
                Text(summary)
                    .font(EquineFont.feedBoard)
                    .foregroundStyle(Color.barnText)
            }
            if !supplements.isEmpty {
                Text("Supplements: \(supplements.joined(separator: ", "))")
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
            }
            if !medications.isEmpty {
                Text("Meds: \(medications.joined(separator: ", "))")
                    .font(EquineFont.caption)
                    .foregroundStyle(Color.alertRed)
            }
        }
    }

    // MARK: - Quick Stats

    private var quickStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Stats", systemImage: "chart.bar.fill")
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statTile(value: "\(horse.healthEvents.count)", label: "Total Events", icon: "list.clipboard")
                statTile(value: "\(horse.overdueEvents.count)", label: "Overdue", icon: "exclamationmark.triangle", isAlert: !horse.overdueEvents.isEmpty)
                statTile(value: costString, label: "30-Day Costs", icon: "dollarsign.circle")
                statTile(value: "\(horse.upcomingEvents.count)", label: "Upcoming", icon: "calendar")
            }

            Button {
                showingAnalytics = true
            } label: {
                Label("View Full Analytics", systemImage: "chart.xyaxis.line")
            }
            .buttonStyle(SecondaryButtonStyle())
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .equineCard()
    }

    private var costString: String {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let total = horse.healthEvents
            .filter { $0.date >= thirtyDaysAgo }
            .compactMap(\.cost)
            .reduce(0, +)
        return String(format: "$%.0f", total)
    }

    private func statTile(value: String, label: String, icon: String, isAlert: Bool = false) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isAlert ? Color.alertRed : Color.hunterGreen)
            Text(value)
                .font(EquineFont.headline)
                .foregroundStyle(isAlert ? Color.alertRed : Color.barnText)
            Text(label)
                .font(EquineFont.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isAlert ? Color.alertRed.opacity(0.05) : Color.hunterGreen.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Health History

    private var healthHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Health Events", systemImage: "clock.arrow.circlepath")
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)

            if horse.recentEvents.isEmpty {
                Text("No events in the last 30 days.")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(horse.recentEvents.prefix(5)) { event in
                    HStack(spacing: 10) {
                        Image(systemName: event.type.iconName)
                            .foregroundStyle(Color.hunterGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.type.rawValue)
                                .font(EquineFont.headline)
                            Text(event.date, style: .date)
                                .font(EquineFont.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let cost = event.cost {
                            Text(String(format: "$%.0f", cost))
                                .font(EquineFont.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .equineCard()
    }

    // MARK: - Actions

    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button {
                generateAndShareReport()
            } label: {
                Label("Generate Owner Report (PDF)", systemImage: "doc.richtext")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                showingAddEvent = true
            } label: {
                Label("Log Health Event", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .equineCard()
    }

    // MARK: - PDF Generation

    private func generateAndShareReport() {
        guard let data = PDFReportService.generateReport(for: horse) else {
            HapticManager.notification(.error)
            return
        }
        pdfData = data
        showingShareSheet = true
    }
}

// MARK: - ShareSheet (UIKit bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        HorseProfileView(horse: PreviewContainer.sampleHorse())
    }
    .modelContainer(PreviewContainer.shared.container)
}

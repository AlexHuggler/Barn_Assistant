import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    let horse: Horse
    @Environment(\.dismiss) private var dismiss

    private var events: [HealthEvent] { horse.healthEvents }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    costTrendCard
                    categoryBreakdownCard
                    cycleComplianceCard
                    predictiveCostCard
                    recommendationsCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Cost Trend

    private var costTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cost Trend (6 Months)", systemImage: "chart.line.uptrend.xyaxis")
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)

            let monthlyData = monthlyCostData()
            if monthlyData.isEmpty {
                Text("No cost data available yet.")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            } else {
                Chart(monthlyData) { item in
                    BarMark(
                        x: .value("Month", item.label),
                        y: .value("Cost", item.cost)
                    )
                    .foregroundStyle(Color.hunterGreen.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartYAxisLabel("USD")

                let totalCost = monthlyData.map(\.cost).reduce(0, +)
                let avgMonthly = monthlyData.isEmpty ? 0 : totalCost / Double(monthlyData.count)
                HStack {
                    VStack(alignment: .leading) {
                        Text("6-Month Total")
                            .font(EquineFont.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "$%.0f", totalCost))
                            .font(EquineFont.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Monthly Average")
                            .font(EquineFont.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "$%.0f", avgMonthly))
                            .font(EquineFont.headline)
                    }
                }
            }
        }
        .equineCard()
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cost by Category", systemImage: "chart.pie.fill")
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)

            let categoryData = costByCategory()
            if categoryData.isEmpty {
                Text("No cost data recorded.")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(categoryData, id: \.type) { item in
                    HStack {
                        Image(systemName: item.type.iconName)
                            .foregroundStyle(Color.hunterGreen)
                            .frame(width: 24)
                        Text(item.type.rawValue)
                            .font(EquineFont.body)
                        Spacer()
                        Text(String(format: "$%.0f", item.cost))
                            .font(EquineFont.headline)
                            .foregroundStyle(Color.barnText)
                        Text("(\(item.count))")
                            .font(EquineFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .equineCard()
    }

    // MARK: - Cycle Compliance

    private var cycleComplianceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Maintenance Cycle Compliance", systemImage: "clock.badge.checkmark.fill")
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)

            ForEach(HealthEventType.allCases) { type in
                let typeEvents = events.filter { $0.type == type }.sorted { $0.date < $1.date }
                let intervals = cycleIntervals(for: typeEvents)

                HStack {
                    Image(systemName: type.iconName)
                        .foregroundStyle(Color.hunterGreen)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.rawValue)
                            .font(EquineFont.headline)
                        if intervals.isEmpty {
                            Text("Not enough data")
                                .font(EquineFont.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            let avg = intervals.reduce(0, +) / intervals.count
                            Text("Avg: \(avg) days | \(type.defaultCycleDescription)")
                                .font(EquineFont.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    complianceIndicator(for: type, intervals: intervals)
                }
                .padding(.vertical, 4)
            }
        }
        .equineCard()
    }

    private func complianceIndicator(for type: HealthEventType, intervals: [Int]) -> some View {
        guard let avg = intervals.isEmpty ? nil : intervals.reduce(0, +) / intervals.count else {
            return AnyView(
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
            )
        }

        let isOnTrack = avg <= CycleThreshold.maxDays(for: type)

        return AnyView(
            Image(systemName: isOnTrack ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isOnTrack ? Color.pastureGreen : Color.alertRed)
        )
    }

    // MARK: - Predictive Cost

    private var predictiveCostCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Projected Annual Cost", systemImage: "chart.line.flattrend.xyaxis")
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)

            let projected = projectedAnnualCost()
            if projected > 0 {
                Text(String(format: "$%.0f", projected))
                    .font(EquineFont.largeTitle)
                    .foregroundStyle(Color.hunterGreen)
                Text("Based on historical spending patterns. Keeping maintenance on schedule can reduce emergency costs by up to 30%.")
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Add cost data to health events to see projections.")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }
        }
        .equineCard()
    }

    // MARK: - Recommendations

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Insights & Recommendations", systemImage: "lightbulb.fill")
                .font(EquineFont.title)
                .foregroundStyle(Color.saddleBrown)

            ForEach(generateInsights(), id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(Color.hunterGreen)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(insight)
                        .font(EquineFont.body)
                        .foregroundStyle(Color.barnText)
                }
                .padding(.vertical, 2)
            }
        }
        .equineCard()
    }

    // MARK: - Data Helpers

    private struct MonthlyCost: Identifiable {
        let label: String
        let cost: Double
        var id: String { label }
    }

    private struct CategoryCost {
        let type: HealthEventType
        let cost: Double
        let count: Int
    }

    private func monthlyCostData() -> [MonthlyCost] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var result: [MonthlyCost] = []
        for monthOffset in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: .now) else { continue }
            let components = calendar.dateComponents([.year, .month], from: monthDate)
            let cost = events
                .filter {
                    let eventComponents = calendar.dateComponents([.year, .month], from: $0.date)
                    return eventComponents.year == components.year && eventComponents.month == components.month
                }
                .compactMap(\.cost)
                .reduce(0, +)
            result.append(MonthlyCost(label: formatter.string(from: monthDate), cost: cost))
        }
        return result
    }

    private func costByCategory() -> [CategoryCost] {
        HealthEventType.allCases.compactMap { type in
            let typeEvents = events.filter { $0.type == type && $0.cost != nil }
            guard !typeEvents.isEmpty else { return nil }
            let total = typeEvents.compactMap(\.cost).reduce(0, +)
            return CategoryCost(type: type, cost: total, count: typeEvents.count)
        }
    }

    private func cycleIntervals(for sortedEvents: [HealthEvent]) -> [Int] {
        guard sortedEvents.count >= 2 else { return [] }
        return zip(sortedEvents, sortedEvents.dropFirst()).compactMap { pair in
            Calendar.current.dateComponents([.day], from: pair.0.date, to: pair.1.date).day
        }
    }

    private func projectedAnnualCost() -> Double {
        let sixMonthsAgo = Calendar.current.safeDate(byAdding: .month, value: -6, to: .now)
        let recentCosts = events
            .filter { $0.date >= sixMonthsAgo }
            .compactMap(\.cost)
            .reduce(0, +)
        return recentCosts * 2 // Extrapolate to annual
    }

    private func generateInsights() -> [String] {
        var insights: [String] = []

        let overdueCount = horse.overdueEvents.count
        if overdueCount > 0 {
            insights.append("You have \(overdueCount) overdue maintenance item\(overdueCount == 1 ? "" : "s"). Scheduling these promptly can prevent more expensive interventions.")
        }

        let farrierEvents = events.filter { $0.type == .farrier }.sorted { $0.date < $1.date }
        let farrierIntervals = cycleIntervals(for: farrierEvents)
        if let avg = farrierIntervals.isEmpty ? nil : farrierIntervals.reduce(0, +) / farrierIntervals.count {
            if avg > 56 {
                insights.append("Farrier visits average \(avg) days apart. Consider tightening to 6-8 weeks to prevent hoof-related lameness issues.")
            } else {
                insights.append("Farrier schedule is on track with an average of \(avg) days between visits.")
            }
        }

        let dewormEvents = events.filter { $0.type == .deworming }
        if dewormEvents.count >= 2 {
            let lastDeworming = dewormEvents.sorted { $0.date > $1.date }.first
            if let last = lastDeworming, let daysSince = Calendar.current.dateComponents([.day], from: last.date, to: .now).day, daysSince > 70 {
                insights.append("Last deworming was \(daysSince) days ago. Consider a fecal egg count to determine if deworming is needed.")
            }
        }

        let totalCost = events.compactMap(\.cost).reduce(0, +)
        if totalCost > 0 {
            let costByType = Dictionary(grouping: events.filter { $0.cost != nil }, by: \.type)
            if let maxType = costByType.max(by: { ($0.value.compactMap(\.cost).reduce(0, +)) < ($1.value.compactMap(\.cost).reduce(0, +)) }) {
                let typeCost = maxType.value.compactMap(\.cost).reduce(0, +)
                let percentage = Int((typeCost / totalCost) * 100)
                insights.append("\(maxType.key.rawValue) accounts for \(percentage)% of total care costs. Consider preventative measures to reduce this.")
            }
        }

        if insights.isEmpty {
            insights.append("Keep logging health events and costs to unlock personalized insights for \(horse.name).")
        }

        return insights
    }
}

#Preview {
    AnalyticsDashboardView(horse: PreviewContainer.sampleHorse())
        .modelContainer(PreviewContainer.shared.container)
}

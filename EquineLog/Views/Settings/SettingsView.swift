import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var horses: [Horse]
    @AppStorage("barnModeUnlocked") private var barnModeUnlocked = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                subscriptionSection
                barnInfoSection
                aboutSection
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section("Subscription") {
            HStack {
                Image(systemName: barnModeUnlocked ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(barnModeUnlocked ? Color.pastureGreen : Color.saddleBrown)
                VStack(alignment: .leading, spacing: 2) {
                    Text(barnModeUnlocked ? "Barn Mode Active" : "Free Plan")
                        .font(EquineFont.headline)
                    Text(barnModeUnlocked
                         ? "Unlimited horses and full features."
                         : "1 horse included. Upgrade for unlimited.")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !barnModeUnlocked {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.saddleBrown)
                        Text("Upgrade to Barn Mode")
                            .font(EquineFont.headline)
                            .foregroundStyle(Color.barnText)
                        Spacer()
                        Text("$19.99/mo")
                            .font(EquineFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Barn Info

    private var barnInfoSection: some View {
        Section("Your Barn") {
            HStack {
                Text("Horses")
                Spacer()
                Text("\(horses.count)")
                    .foregroundStyle(.secondary)
            }

            let overdueCount = horses.flatMap(\.overdueEvents).count
            HStack {
                Text("Overdue Maintenance")
                Spacer()
                Text("\(overdueCount)")
                    .foregroundStyle(overdueCount > 0 ? Color.alertRed : .secondary)
            }

            NavigationLink {
                FeedResetView()
            } label: {
                Label("Reset Daily Feed Status", systemImage: "arrow.counterclockwise")
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0 (MVP)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Built with")
                Spacer()
                Text("SwiftUI + SwiftData")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Feed Reset View

struct FeedResetView: View {
    @Query(sort: \Horse.name) private var horses: [Horse]
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false

    var body: some View {
        List {
            Section {
                Text("Reset the 'fed' status for all horses. Use this at the start of a new day.")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) {
                    showConfirmation = true
                } label: {
                    Label("Reset All Feeds", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Reset Feeds")
        .confirmationDialog(
            "Reset All Feeds",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset for \(horses.count) horse\(horses.count == 1 ? "" : "s")", role: .destructive) {
                resetAllFeeds()
                HapticManager.notification(.success)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will mark all horses as unfed for the current feeding slot. This is typically done at the start of a new day.")
        }
    }

    private func resetAllFeeds() {
        for horse in horses {
            horse.feedSchedule?.resetDailyStatus()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewContainer.shared.container)
}

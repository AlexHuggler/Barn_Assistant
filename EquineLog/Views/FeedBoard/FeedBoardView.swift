import SwiftUI
import SwiftData

struct FeedBoardView: View {
    @Query(sort: \Horse.name) private var horses: [Horse]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("barnModeUnlocked") private var barnModeUnlocked = false
    @State private var viewModel = FeedBoardViewModel()
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if horses.isEmpty {
                    emptyStateView
                } else {
                    feedList
                }
            }
            .navigationTitle("Feed Board")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    slotIndicator
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Gate: if 1+ horse exists and not subscribed, show paywall first
                        if !horses.isEmpty && !barnModeUnlocked {
                            showPaywall = true
                        } else {
                            viewModel.showingAddHorse = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.hunterGreen)
                    }
                    .accessibilityLabel("Add horse")
                }
            }
            .sheet(isPresented: $viewModel.showingAddHorse) {
                AddHorseView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $viewModel.showingQuickLog) {
                if let horse = viewModel.quickLogHorse {
                    AddHealthEventView(horses: [horse])
                }
            }
            .confirmationDialog(
                "Delete Horse",
                isPresented: $viewModel.showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete \(viewModel.horseToDelete?.name ?? "Horse")", role: .destructive) {
                    if let horse = viewModel.horseToDelete {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            modelContext.delete(horse)
                        }
                        HapticManager.notification(.warning)
                    }
                    viewModel.horseToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    viewModel.horseToDelete = nil
                }
            } message: {
                Text("This will permanently delete \(viewModel.horseToDelete?.name ?? "this horse") and all associated health records and feed data. This cannot be undone.")
            }
            .overlay {
                if viewModel.allFedCelebration {
                    allFedBanner
                }
            }
            .onAppear {
                viewModel.autoResetIfNewDay(horses: horses)
            }
        }
    }

    // MARK: - Subviews

    private var slotIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.currentSlot == .am ? "sunrise.fill" : "sunset.fill")
                .font(.caption2)
                .foregroundStyle(viewModel.currentSlot == .am ? Color.saddleBrown : Color.hunterGreen)
            Text(viewModel.currentSlot.rawValue + " Feed")
                .font(EquineFont.caption)
                .foregroundStyle(Color.barnText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.parchment)
        .clipShape(Capsule())
        .accessibilityLabel("Current feeding slot: \(viewModel.currentSlot.rawValue)")
    }

    private var feedList: some View {
        List {
            // Filter bar
            Section {
                Picker("Filter", selection: $viewModel.filterFedStatus) {
                    ForEach(FeedBoardViewModel.FedFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            // Horse feed rows
            Section {
                let filtered = viewModel.filteredHorses(horses)
                ForEach(filtered) { horse in
                    NavigationLink(destination: HorseProfileView(horse: horse)) {
                        FeedBoardRow(
                            horse: horse,
                            isFed: viewModel.isFed(horse: horse),
                            currentSlot: viewModel.currentSlot.rawValue,
                            onToggleFed: {
                                withAnimation(.snappy(duration: 0.3)) {
                                    viewModel.toggleFed(for: horse, allHorses: horses)
                                }
                            }
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.confirmDelete(horse: horse)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            viewModel.requestQuickLog(horse: horse)
                        } label: {
                            Label("Log Event", systemImage: "heart.text.clipboard")
                        }
                        .tint(Color.hunterGreen)
                    }
                }
            } header: {
                feedProgressHeader
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, prompt: "Search horses...")
        .refreshable {
            viewModel.autoResetIfNewDay(horses: horses)
            HapticManager.impact(.light)
        }
    }

    private var feedProgressHeader: some View {
        let total = horses.count
        let fed = viewModel.fedCount(from: horses)
        let progress = total > 0 ? Double(fed) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(viewModel.currentSlot.rawValue) Progress")
                    .font(EquineFont.caption)
                Spacer()
                Text("\(fed)/\(total) fed")
                    .font(EquineFont.caption)
                    .foregroundStyle(fed == total ? Color.pastureGreen : Color.barnText)
            }
            ProgressView(value: progress)
                .tint(fed == total ? Color.pastureGreen : Color.hunterGreen)
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "horse")
                .font(.system(size: 64))
                .foregroundStyle(Color.hunterGreen.opacity(0.4))

            Text("No Horses Yet")
                .font(EquineFont.title)
                .foregroundStyle(Color.barnText)

            Text("Add your first horse to get started\nwith the digital feed board.")
                .font(EquineFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Horse") {
                viewModel.showingAddHorse = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(40)
    }

    // MARK: - All-Fed Celebration Banner

    private var allFedBanner: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("All \(viewModel.currentSlot.rawValue) Feeds Complete")
                        .font(EquineFont.headline)
                        .foregroundStyle(.white)
                    Text("\(horses.count) horse\(horses.count == 1 ? "" : "s") fed")
                        .font(EquineFont.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Button {
                    withAnimation(.easeOut(duration: 0.25)) {
                        viewModel.allFedCelebration = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                }
                .accessibilityLabel("Dismiss")
            }
            .padding()
            .background(Color.pastureGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .padding(.horizontal)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.25)) {
                    viewModel.allFedCelebration = false
                }
            }
        }
    }
}

#Preview {
    FeedBoardView()
        .modelContainer(PreviewContainer.shared.container)
}

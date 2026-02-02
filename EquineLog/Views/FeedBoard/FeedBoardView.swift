import SwiftUI
import SwiftData

struct FeedBoardView: View {
    @Query(sort: \Horse.name) private var horses: [Horse]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FeedBoardViewModel()

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
                        viewModel.showingAddHorse = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.hunterGreen)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddHorse) {
                AddHorseView()
            }
        }
    }

    // MARK: - Subviews

    private var slotIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.currentFeedingSlot == "AM" ? Color.saddleBrown : Color.hunterGreen)
                .frame(width: 8, height: 8)
            Text(viewModel.currentFeedingSlot + " Feed")
                .font(EquineFont.caption)
                .foregroundStyle(Color.barnText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.parchment)
        .clipShape(Capsule())
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
                ForEach(viewModel.filteredHorses(horses)) { horse in
                    NavigationLink(destination: HorseProfileView(horse: horse)) {
                        FeedBoardRow(
                            horse: horse,
                            isFed: viewModel.isFed(horse: horse),
                            currentSlot: viewModel.currentFeedingSlot,
                            onToggleFed: { viewModel.toggleFed(for: horse) }
                        )
                    }
                }
                .onDelete(perform: deleteHorses)
            } header: {
                feedProgressHeader
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, prompt: "Search horses...")
    }

    private var feedProgressHeader: some View {
        let total = horses.count
        let fedCount = horses.filter { viewModel.isFed(horse: $0) }.count
        return HStack {
            Text("\(viewModel.currentFeedingSlot) Progress")
                .font(EquineFont.caption)
            Spacer()
            Text("\(fedCount)/\(total) fed")
                .font(EquineFont.caption)
                .foregroundStyle(fedCount == total ? Color.pastureGreen : Color.barnText)
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

    // MARK: - Actions

    private func deleteHorses(at offsets: IndexSet) {
        let filtered = viewModel.filteredHorses(horses)
        for index in offsets {
            modelContext.delete(filtered[index])
        }
    }
}

#Preview {
    FeedBoardView()
        .modelContainer(PreviewContainer.shared.container)
}

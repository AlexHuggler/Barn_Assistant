import SwiftUI

struct FeedBoardRow: View {
    let horse: Horse
    let isFed: Bool
    let currentSlot: String
    let onToggleFed: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            horseAvatar
            feedContent
            Spacer()
            fedToggle
        }
        .padding(.vertical, 6)
        .background(isFed ? Color.pastureGreen.opacity(0.04) : Color.clear)
        .animation(.easeInOut(duration: 0.25), value: isFed)
    }

    // MARK: - Subviews

    private var horseAvatar: some View {
        Group {
            if let imageData = horse.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "horse.circle.fill")
                    .resizable()
                    .foregroundStyle(Color.hunterGreen.opacity(0.3))
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
        .overlay {
            if isFed {
                Circle()
                    .stroke(Color.pastureGreen, lineWidth: 2)
            }
        }
    }

    private var feedContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(horse.name)
                    .font(EquineFont.headline)
                    .foregroundStyle(isFed ? Color.barnText.opacity(0.6) : Color.barnText)
                    .strikethrough(isFed, color: Color.pastureGreen.opacity(0.5))

                if horse.isClipped {
                    StatusBadge(text: "Clipped", color: .saddleBrown)
                }

                if isFed {
                    StatusBadge(text: "Fed", color: .pastureGreen)
                }
            }

            if let schedule = horse.feedSchedule {
                feedDetails(schedule: schedule)
            } else {
                Text("No feed schedule set")
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func feedDetails(schedule: FeedSchedule) -> some View {
        let feedText = currentSlot == "AM" ? schedule.amSummary : schedule.pmSummary
        let supplements = currentSlot == "AM" ? schedule.amSupplements : schedule.pmSupplements
        let medications = currentSlot == "AM" ? schedule.amMedications : schedule.pmMedications

        VStack(alignment: .leading, spacing: 2) {
            Text(feedText)
                .font(EquineFont.feedBoard)
                .foregroundStyle(isFed ? Color.barnText.opacity(0.5) : Color.barnText)

            if !supplements.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.pastureGreen)
                    Text(supplements.joined(separator: ", "))
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !medications.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "pills.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.alertRed)
                    Text(medications.joined(separator: ", "))
                        .font(EquineFont.caption)
                        .foregroundStyle(Color.alertRed)
                }
            }

            if !schedule.specialInstructions.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.saddleBrown)
                    Text(schedule.specialInstructions)
                        .font(EquineFont.caption)
                        .foregroundStyle(Color.saddleBrown)
                        .lineLimit(1)
                }
            }
        }
    }

    private var fedToggle: some View {
        Button {
            onToggleFed()
        } label: {
            Image(systemName: isFed ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isFed ? Color.pastureGreen : Color.fenceLine)
                .contentTransition(.symbolEffect(.replace))
                .scaleEffect(isFed ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isFed)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFed ? "Marked as fed. Tap to undo." : "Not yet fed. Tap to mark as fed.")
    }
}

#Preview {
    let horse = PreviewContainer.sampleHorse()
    return List {
        FeedBoardRow(horse: horse, isFed: false, currentSlot: "AM", onToggleFed: {})
        FeedBoardRow(horse: horse, isFed: true, currentSlot: "PM", onToggleFed: {})
    }
    .modelContainer(PreviewContainer.shared.container)
}

import SwiftUI

struct BarnSetupStepView: View {
    @Binding var barnName: String
    @Binding var selectedHorseCount: HorseCountRange

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.hunterGreen)

                Text("Tell us about your barn")
                    .font(EquineFont.title)
                    .foregroundStyle(Color.barnText)

                Text("This helps us personalize your experience")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 20) {
                // Barn name (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Barn Name (optional)")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)

                    TextField("e.g., Sunny Meadows Farm", text: $barnName)
                        .textFieldStyle(.roundedBorder)
                        .font(EquineFont.body)
                }

                // Horse count
                VStack(alignment: .leading, spacing: 8) {
                    Text("How many horses?")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(HorseCountRange.allCases) { range in
                            SelectableCard(
                                title: range.displayName,
                                icon: range.icon,
                                isSelected: selectedHorseCount == range
                            ) {
                                selectedHorseCount = range
                                HapticManager.selection()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

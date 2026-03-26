import SwiftUI

struct ExperienceLevelStepView: View {
    @Binding var selectedExperience: ExperienceLevel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.hunterGreen)

                Text("How should we get you started?")
                    .font(EquineFont.title)
                    .foregroundStyle(Color.barnText)

                Text("Choose your pace — you can always replay the tour later")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(ExperienceLevel.allCases) { level in
                    Button {
                        selectedExperience = level
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: level.icon)
                                .font(.title2)
                                .foregroundStyle(selectedExperience == level ? .white : Color.hunterGreen)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.displayName)
                                    .font(EquineFont.headline)
                                    .foregroundStyle(selectedExperience == level ? .white : Color.barnText)

                                Text(level.description)
                                    .font(EquineFont.caption)
                                    .foregroundStyle(selectedExperience == level ? .white.opacity(0.8) : .secondary)
                            }

                            Spacer()

                            if selectedExperience == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(selectedExperience == level ? Color.hunterGreen : Color.parchment.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedExperience == level ? .isSelected : [])
                }
            }
            .padding(.horizontal, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

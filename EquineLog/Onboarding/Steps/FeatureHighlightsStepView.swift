import SwiftUI

struct FeatureHighlightsStepView: View {
    @Bindable var manager: OnboardingManager
    let selectedUseCase: PrimaryUseCase

    var body: some View {
        // Temporarily set the use case so personalizedFeatures reflects the selection
        let _ = { manager.primaryUseCase = selectedUseCase }()

        return VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.hunterGreen)

                Text("Tailored for You")
                    .font(EquineFont.title)
                    .foregroundStyle(Color.barnText)

                Text("Based on your \(selectedUseCase.displayName.lowercased()) setup")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(manager.personalizedFeatures) { feature in
                        HStack(alignment: .top, spacing: 16) {
                            ZStack {
                                Image(systemName: feature.icon)
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(feature.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                if feature.isPrimary {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.saddleBrown)
                                        .offset(x: 18, y: -18)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(feature.title)
                                        .font(EquineFont.headline)
                                        .foregroundStyle(Color.barnText)
                                    if feature.isPrimary {
                                        Text("Key")
                                            .font(.system(.caption2, design: .rounded, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.saddleBrown)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(feature.description)
                                    .font(EquineFont.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding()
                        .background(Color.parchment.opacity(feature.isPrimary ? 0.95 : 0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            feature.isPrimary
                                ? RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(feature.color.opacity(0.3), lineWidth: 1)
                                : nil
                        )
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

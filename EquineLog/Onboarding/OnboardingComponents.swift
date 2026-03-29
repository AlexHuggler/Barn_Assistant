import SwiftUI

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case barnSetup = 1
    case useCase = 2
    case experienceLevel = 3
    case features = 4
    case quickStart = 5

    var id: Int { rawValue }

    var next: OnboardingStep {
        OnboardingStep(rawValue: rawValue + 1) ?? self
    }

    var previous: OnboardingStep {
        OnboardingStep(rawValue: rawValue - 1) ?? self
    }
}

// MARK: - Supporting Views

struct ValuePropRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.hunterGreen)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(EquineFont.headline)
                    .foregroundStyle(Color.barnText)
                Text(description)
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct SelectableCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.hunterGreen)

                Text(title)
                    .font(EquineFont.caption)
                    .foregroundStyle(isSelected ? .white : Color.barnText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.hunterGreen : Color.parchment.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.hunterGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(isSelected ? "Selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct UseCaseCard: View {
    let useCase: PrimaryUseCase
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: useCase.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color.hunterGreen)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(useCase.displayName)
                        .font(EquineFont.headline)
                        .foregroundStyle(isSelected ? .white : Color.barnText)

                    Text(useCase.description)
                        .font(EquineFont.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.hunterGreen : Color.parchment.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(useCase.displayName). \(useCase.description)")
        .accessibilityHint(isSelected ? "Selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(EquineFont.headline)
                    .foregroundStyle(Color.barnText)

                Text(description)
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.parchment.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.hunterGreen)
                .frame(width: 20)

            Text(text)
                .font(EquineFont.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

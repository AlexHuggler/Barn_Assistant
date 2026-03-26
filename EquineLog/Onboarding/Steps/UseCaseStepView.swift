import SwiftUI

struct UseCaseStepView: View {
    @Binding var selectedUseCase: PrimaryUseCase

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.saddleBrown)

                Text("What's your primary focus?")
                    .font(EquineFont.title)
                    .foregroundStyle(Color.barnText)

                Text("We'll highlight the most relevant features")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(PrimaryUseCase.allCases) { useCase in
                    UseCaseCard(
                        useCase: useCase,
                        isSelected: selectedUseCase == useCase
                    ) {
                        selectedUseCase = useCase
                        HapticManager.selection()
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

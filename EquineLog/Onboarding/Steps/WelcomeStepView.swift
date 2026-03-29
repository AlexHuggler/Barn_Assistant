import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon / Logo
            ZStack {
                Circle()
                    .fill(Color.hunterGreen.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "horse.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.hunterGreen)
                    .symbolEffect(.pulse, options: .repeating.speed(0.3))
            }

            VStack(spacing: 12) {
                Text("Welcome to EquineLog")
                    .font(EquineFont.largeTitle)
                    .foregroundStyle(Color.barnText)

                Text("Your complete barn management companion")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Key value props
            VStack(alignment: .leading, spacing: 16) {
                ValuePropRow(icon: "checklist", title: "Track Feeding", description: "Never miss a meal with daily AM/PM tracking")
                ValuePropRow(icon: "heart.text.clipboard", title: "Health Records", description: "Vet, farrier, and dental reminders")
                ValuePropRow(icon: "cloud.sun.fill", title: "Weather Alerts", description: "Smart blanket recommendations")
            }
            .padding(.top, 16)
            .padding(.horizontal, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

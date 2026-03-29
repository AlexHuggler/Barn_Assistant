import SwiftUI

struct QuickStartStepView: View {
    @Binding var horseName: String
    @Binding var ownerName: String
    @Binding var wantsToAddHorse: Bool
    let selectedExperience: ExperienceLevel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.hunterGreen)

                Text("You're all set!")
                    .font(EquineFont.title)
                    .foregroundStyle(Color.barnText)

                Text("Would you like to add your first horse now?")
                    .font(EquineFont.body)
                    .foregroundStyle(.secondary)
            }

            // Quick add option
            VStack(spacing: 16) {
                Button {
                    withAnimation {
                        wantsToAddHorse.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: wantsToAddHorse ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(wantsToAddHorse ? Color.hunterGreen : .secondary)
                        Text("Yes, add a horse now")
                            .foregroundStyle(Color.barnText)
                        Spacer()
                    }
                    .padding()
                    .background(Color.parchment.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                if wantsToAddHorse {
                    VStack(spacing: 12) {
                        TextField("Horse name", text: $horseName)
                            .textFieldStyle(.roundedBorder)
                            .font(EquineFont.body)

                        TextField("Owner name", text: $ownerName)
                            .textFieldStyle(.roundedBorder)
                            .font(EquineFont.body)
                    }
                    .padding()
                    .background(Color.hunterGreen.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 8)

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                if selectedExperience != .techSavvy {
                    Text("What's next")
                        .font(EquineFont.caption)
                        .foregroundStyle(.secondary)
                    TipRow(icon: "hand.wave.fill", text: "We'll give you a quick guided tour")
                }
                TipRow(icon: "hand.tap.fill", text: "Tap a horse to mark as fed")
                TipRow(icon: "plus.circle.fill", text: "Use the + button to add horses")
                TipRow(icon: "gearshape.fill", text: "Replay this tutorial in Settings")
            }
            .padding()
            .background(Color.parchment.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

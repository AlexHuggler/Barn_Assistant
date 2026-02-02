import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("barnModeUnlocked") private var barnModeUnlocked = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.saddleBrown)

                // Title
                VStack(spacing: 8) {
                    Text("Barn Mode")
                        .font(EquineFont.largeTitle)
                        .foregroundStyle(Color.barnText)
                    Text("Manage your entire barn.")
                        .font(EquineFont.body)
                        .foregroundStyle(.secondary)
                }

                // Features
                VStack(alignment: .leading, spacing: 14) {
                    featureRow(icon: "horse.circle.fill", text: "Unlimited horses")
                    featureRow(icon: "heart.text.clipboard.fill", text: "Full health tracking & analytics")
                    featureRow(icon: "doc.richtext.fill", text: "PDF owner reports")
                    featureRow(icon: "cloud.sun.fill", text: "Blanketing recommendations")
                    featureRow(icon: "bell.badge.fill", text: "Maintenance reminders")
                }
                .padding(.horizontal, 30)

                Spacer()

                // Price & CTA
                VStack(spacing: 12) {
                    Button {
                        // In production, this would trigger StoreKit 2 purchase flow.
                        // For MVP, we simulate the unlock.
                        barnModeUnlocked = true
                        dismiss()
                    } label: {
                        VStack(spacing: 4) {
                            Text("Subscribe — $19.99/month")
                                .font(EquineFont.headline)
                            Text("Cancel anytime")
                                .font(EquineFont.caption)
                                .opacity(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.hunterGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button("Restore Purchases") {
                        // StoreKit restore logic would go here
                    }
                    .font(EquineFont.caption)
                    .foregroundStyle(.secondary)

                    Text("Payment will be charged to your Apple ID account. Subscription auto-renews monthly unless cancelled at least 24 hours before the end of the current period.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.hunterGreen)
                .frame(width: 30)
            Text(text)
                .font(EquineFont.body)
                .foregroundStyle(Color.barnText)
        }
    }
}

#Preview {
    PaywallView()
}

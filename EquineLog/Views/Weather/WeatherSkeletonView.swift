import SwiftUI

struct WeatherSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Weather icon placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.fenceLine.opacity(0.3))
                .frame(width: 48, height: 48)

            // Temperature placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.fenceLine.opacity(0.3))
                .frame(width: 100, height: 36)

            // Condition text placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.fenceLine.opacity(0.3))
                .frame(width: 140, height: 18)

            // Humidity and wind row
            HStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.fenceLine.opacity(0.3))
                    .frame(width: 80, height: 16)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.fenceLine.opacity(0.3))
                    .frame(width: 80, height: 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .equineCard()
        .shimmer()
        .accessibilityLabel("Loading weather data")
    }
}

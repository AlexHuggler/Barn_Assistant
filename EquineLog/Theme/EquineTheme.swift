import SwiftUI

// MARK: - Color Palette

extension Color {
    /// Hunter Green — primary brand color.
    static let hunterGreen = Color(red: 0.13, green: 0.37, blue: 0.18)

    /// Saddle Brown — warm accent color.
    static let saddleBrown = Color(red: 0.55, green: 0.27, blue: 0.07)

    /// Soft cream background for cards.
    static let parchment = Color(red: 0.97, green: 0.95, blue: 0.91)

    /// Dark text for high contrast on light backgrounds.
    static let barnText = Color(red: 0.15, green: 0.12, blue: 0.10)

    /// Subtle divider / border color.
    static let fenceLine = Color(red: 0.80, green: 0.75, blue: 0.68)

    /// Overdue / alert red.
    static let alertRed = Color(red: 0.78, green: 0.15, blue: 0.12)

    /// Success green for completed actions.
    static let pastureGreen = Color(red: 0.20, green: 0.62, blue: 0.28)
}

// MARK: - Typography

struct EquineFont {
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title = Font.system(.title2, design: .rounded, weight: .semibold)
    static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let body = Font.system(.body, design: .default, weight: .regular)
    static let caption = Font.system(.caption, design: .default, weight: .medium)
    static let feedBoard = Font.system(.title3, design: .monospaced, weight: .medium)
}

// MARK: - Card Style

struct EquineCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.parchment)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func equineCard() -> some View {
        modifier(EquineCardStyle())
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(EquineFont.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.hunterGreen)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(EquineFont.headline)
            .foregroundStyle(Color.hunterGreen)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.hunterGreen.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(EquineFont.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

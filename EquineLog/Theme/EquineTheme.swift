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
// All fonts use semantic text styles that automatically scale with Dynamic Type.
// Users can adjust text size in Settings > Accessibility > Display & Text Size.

struct EquineFont {
    /// Large display title - scales with Dynamic Type
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)

    /// Section title - scales with Dynamic Type
    static let title = Font.system(.title2, design: .rounded, weight: .semibold)

    /// Row/card header - scales with Dynamic Type
    static let headline = Font.system(.headline, design: .rounded, weight: .semibold)

    /// Standard body text - scales with Dynamic Type
    static let body = Font.system(.body, design: .default, weight: .regular)

    /// Secondary/metadata text - scales with Dynamic Type
    static let caption = Font.system(.caption, design: .default, weight: .medium)

    /// Feed board text (monospaced for alignment) - scales with Dynamic Type
    static let feedBoard = Font.system(.subheadline, design: .monospaced, weight: .medium)
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
            .accessibilityLabel(text)
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
            Text(message)
                .font(EquineFont.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let icon: String
    let color: Color
    let duration: TimeInterval

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isShowing {
                    ToastView(message: message, icon: icon, color: color)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    isShowing = false
                                }
                            }
                        }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill", color: Color = .pastureGreen, duration: TimeInterval = 2.0) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, icon: icon, color: color, duration: duration))
    }
}

// MARK: - Loading Button Style

struct LoadingButtonStyle: ButtonStyle {
    let isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.8)
            }
            configuration.label
        }
        .font(EquineFont.headline)
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(isLoading ? Color.hunterGreen.opacity(0.7) : Color.hunterGreen)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        .allowsHitTesting(!isLoading)
    }
}

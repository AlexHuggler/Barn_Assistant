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

// MARK: - Chip Input View

struct ChipInputView: View {
    let label: String
    @Binding var chips: [String]
    var isFocused: Bool = false
    var onCommitFocus: (() -> Void)? = nil

    @State private var inputText = ""
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !chips.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(chips, id: \.self) { chip in
                        HStack(spacing: 4) {
                            Text(chip)
                                .font(EquineFont.caption)
                                .foregroundStyle(Color.barnText)
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    chips.removeAll { $0 == chip }
                                }
                                HapticManager.impact(.light)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.barnText.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.parchment)
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            TextField(label, text: $inputText)
                .font(EquineFont.body)
                .focused($textFieldFocused)
                .autocorrectionDisabled()
                .onSubmit {
                    if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        addChip()
                    } else {
                        onCommitFocus?()
                    }
                }
                .onChange(of: inputText) { _, newValue in
                    if newValue.last == "," {
                        inputText = String(newValue.dropLast())
                        addChip()
                    }
                }
                .onChange(of: isFocused) { _, newValue in
                    textFieldFocused = newValue
                }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }

    private func addChip() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !chips.contains(trimmed) else {
            inputText = ""
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            chips.append(trimmed)
        }
        inputText = ""
        HapticManager.selection()
    }
}

/// Simple flow layout that wraps chips to the next line.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Validation Indicator

struct ValidationIndicatorView: View {
    let validation: FormValidation.Result
    let isVisible: Bool

    var body: some View {
        if isVisible {
            Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(validation.isValid ? Color.pastureGreen : Color.alertRed)
                .font(.body)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

struct ValidationMessageView: View {
    let validation: FormValidation.Result
    let isVisible: Bool

    var body: some View {
        if isVisible, let msg = validation.message {
            Text(msg)
                .font(.caption)
                .foregroundStyle(Color.alertRed)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    var icon: String? = nil

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(EquineFont.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? selectedColor : Color.parchment)
            .foregroundStyle(isSelected ? .white : Color.barnText)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - View Constants

enum ViewConstants {
    static let toastDuration: TimeInterval = 2.0
    static let feedbackDelay: TimeInterval = 0.8
    static let undoBannerDuration: TimeInterval = 4.0
    static let tourStepDelay: TimeInterval = 0.6
    static let celebrationDuration: TimeInterval = 3.0
}

// MARK: - Keyboard Navigation Toolbar

struct KeyboardNavToolbar<F: Hashable>: ViewModifier {
    @FocusState.Binding var focusedField: F?
    let fields: [F]

    private var currentIndex: Int? {
        guard let focused = focusedField else { return nil }
        return fields.firstIndex(of: focused)
    }

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    moveFocus(by: -1)
                    HapticManager.selection()
                } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(currentIndex == nil || currentIndex == 0)

                Button {
                    moveFocus(by: 1)
                    HapticManager.selection()
                } label: {
                    Image(systemName: "chevron.down")
                }
                .disabled(currentIndex == nil || currentIndex == fields.count - 1)

                Spacer()

                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }

    private func moveFocus(by offset: Int) {
        guard let current = currentIndex else { return }
        let next = current + offset
        guard next >= 0, next < fields.count else { return }
        focusedField = fields[next]
    }
}

extension View {
    func keyboardNav<F: Hashable>(focusedField: FocusState<F?>.Binding, fields: [F]) -> some View {
        modifier(KeyboardNavToolbar(focusedField: focusedField, fields: fields))
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

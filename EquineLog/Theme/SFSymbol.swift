import SwiftUI

/// Type-safe SF Symbol references for the EquineLog app.
/// Using this enum ensures compile-time safety and prevents typos in symbol names.
enum SFSymbol: String {
    // MARK: - Navigation & UI Control

    case arrowLeft = "chevron.left"
    case arrowRight = "chevron.right"
    case arrowRightCircleFill = "arrow.right.circle.fill"
    case ellipsisCircle = "ellipsis.circle"
    case close = "xmark.circle.fill"
    case filter = "line.3.horizontal.decrease.circle.fill"

    // MARK: - Actions

    case add = "plus.circle.fill"
    case edit = "pencil"
    case delete = "trash"
    case remove = "minus.circle"
    case copy = "doc.on.doc.fill"
    case undo = "arrow.uturn.backward.circle.fill"
    case reset = "arrow.counterclockwise"
    case tap = "hand.tap.fill"

    // MARK: - Status & Feedback

    case checkmarkCircleFill = "checkmark.circle.fill"
    case checkmarkSealFill = "checkmark.seal.fill"
    case exclamationCircleFill = "exclamationmark.circle.fill"
    case exclamationTriangle = "exclamationmark.triangle"
    case exclamationTriangleFill = "exclamationmark.triangle.fill"
    case cloudWarning = "exclamationmark.icloud.fill"
    case sparkles = "sparkles"
    case starFill = "star.fill"
    case lightbulbFill = "lightbulb.fill"

    // MARK: - Health & Medical

    case healthClipboard = "heart.text.clipboard"
    case healthClipboardFill = "heart.text.clipboard.fill"
    case vet = "cross.case.fill"
    case pills = "pills.fill"
    case mouth = "mouth.fill"
    case bellBadgeFill = "bell.badge.fill"

    // MARK: - Horse Care

    case horse = "horse"
    case horseCircleFill = "horse.circle.fill"
    case farrier = "hammer.fill"
    case leaf = "leaf.fill"
    case cameraCircleFill = "camera.circle.fill"

    // MARK: - Feed & Schedule

    case feedBoard = "house.fill"
    case cupAndSaucer = "cup.and.saucer.fill"
    case checklist = "checklist"
    case gearshapeFill = "gearshape.fill"

    // MARK: - Calendar & Time

    case calendar = "calendar"
    case calendarCheckmark = "calendar.badge.checkmark"
    case calendarClock = "calendar.badge.clock"
    case clockArrow = "clock.arrow.circlepath"
    case clockCheckmark = "clock.badge.checkmark.fill"
    case listClipboard = "list.clipboard"

    // MARK: - Charts & Analytics

    case chartBar = "chart.bar.fill"
    case chartLine = "chart.xyaxis.line"
    case chartLineUptrend = "chart.line.uptrend.xyaxis"
    case chartLineFlattrend = "chart.line.flattrend.xyaxis"
    case chartPie = "chart.pie.fill"

    // MARK: - Finance

    case dollarCircle = "dollarsign.circle"

    // MARK: - Weather

    case cloudSunFill = "cloud.sun.fill"
    case sunMaxFill = "sun.max.fill"
    case wind = "wind"
    case snowflake = "snowflake"
    case snowflakeCircleFill = "snowflake.circle.fill"
    case thermometerSnowflake = "thermometer.snowflake"
    case humidityFill = "humidity.fill"
    case locationCircleFill = "location.circle.fill"

    // MARK: - Documents & Reports

    case docBadgePlus = "doc.badge.plus"
    case docRichtext = "doc.richtext"
    case docRichtextFill = "doc.richtext.fill"

    // MARK: - Use Cases

    case heartFill = "heart.fill"
    case building = "building.2.fill"
    case equestrian = "figure.equestrian.sports"
    case flagCheckered = "flag.checkered"

    // MARK: - Count Badges

    case oneCircleFill = "1.circle.fill"
    case fiveCircleFill = "5.circle.fill"
    case fifteenCircleFill = "15.circle.fill"
    case infinityCircleFill = "infinity.circle.fill"
}

// MARK: - SwiftUI Extensions

extension SFSymbol {
    /// Returns a SwiftUI Image view for this symbol.
    var image: Image {
        Image(systemName: rawValue)
    }

    /// Returns a SwiftUI Label view with the symbol and provided text.
    func label(_ text: String) -> Label<Text, Image> {
        Label(text, systemImage: rawValue)
    }
}

// MARK: - View Extension for Convenience

extension View {
    /// Creates an Image with the specified SF Symbol.
    func sfSymbol(_ symbol: SFSymbol) -> some View {
        Image(systemName: symbol.rawValue)
    }
}

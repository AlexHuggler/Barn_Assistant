import Foundation

/// Blanket recommendation engine based on temperature and clipping status.
struct BlanketRecommendation {

    enum BlanketType: String {
        case none = "No Blanket"
        case lightSheet = "Light Sheet"
        case mediumWeight = "Medium Weight"
        case heavyWeight = "Heavy Weight"
        case heavyWeightPlus = "Heavy Weight + Liner / Neck Cover"
        case noneOrLight = "No Blanket / Light Sheet"
    }

    /// Returns the recommended blanket given temperature in Fahrenheit and clip status.
    static func recommend(temperatureF: Double, isClipped: Bool) -> BlanketType {
        switch (temperatureF, isClipped) {
        // > 60°F
        case (let t, false) where t > 60:
            return .none
        case (let t, true) where t > 60:
            return .noneOrLight

        // 50°F - 60°F
        case (let t, false) where t >= 50:
            return .none
        case (let t, true) where t >= 50:
            return .lightSheet

        // 40°F - 50°F
        case (let t, false) where t >= 40:
            return .lightSheet
        case (let t, true) where t >= 40:
            return .mediumWeight

        // 30°F - 40°F
        case (let t, false) where t >= 30:
            return .mediumWeight
        case (let t, true) where t >= 30:
            return .heavyWeight

        // < 30°F
        case (_, false):
            return .heavyWeight
        case (_, true):
            return .heavyWeightPlus
        }
    }

    /// Human-friendly description for each blanket type.
    static func description(for type: BlanketType) -> String {
        switch type {
        case .none:
            return "Your horse is comfortable without a blanket at this temperature."
        case .noneOrLight:
            return "A light sheet is optional. Monitor if the horse seems chilly."
        case .lightSheet:
            return "A lightweight turnout sheet will keep your horse comfortable."
        case .mediumWeight:
            return "A medium-weight blanket (200g fill) is recommended."
        case .heavyWeight:
            return "A heavy-weight blanket (300g+ fill) is needed for warmth."
        case .heavyWeightPlus:
            return "Layer up — heavy blanket with liner and neck cover for extreme cold."
        }
    }

    /// Returns the SF Symbol icon name for the blanket type.
    static func iconName(for type: BlanketType) -> String {
        switch type {
        case .none: return "sun.max.fill"
        case .noneOrLight: return "cloud.sun.fill"
        case .lightSheet: return "wind"
        case .mediumWeight: return "cloud.fill"
        case .heavyWeight: return "snowflake"
        case .heavyWeightPlus: return "snowflake.circle.fill"
        }
    }
}

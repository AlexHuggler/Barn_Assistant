import Foundation
import PDFKit
import UIKit

/// Generates PDF reports for horse health and activity summaries.
struct PDFReportService {

    /// Generates a 30-day health report for a given horse.
    static func generateReport(for horse: Horse) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let margin: CGFloat = 50
        let contentWidth = pageRect.width - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()
            var yPosition: CGFloat = margin

            // Header
            yPosition = drawHeader(horse: horse, in: pageRect, at: yPosition, width: contentWidth, margin: margin)

            // Divider
            yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context.cgContext)

            // Health Events (Last 30 Days)
            yPosition = drawSectionTitle("Health Events — Last 30 Days", at: yPosition, margin: margin)

            let recentEvents = horse.recentEvents
            if recentEvents.isEmpty {
                yPosition = drawBodyText("No health events recorded in the last 30 days.", at: yPosition, margin: margin, width: contentWidth)
            } else {
                for event in recentEvents {
                    // Check if we need a new page
                    if yPosition > pageRect.height - 100 {
                        context.beginPage()
                        yPosition = margin
                    }
                    yPosition = drawEventRow(event, at: yPosition, margin: margin, width: contentWidth)
                }
            }

            yPosition += 20

            // Upcoming Maintenance
            if yPosition > pageRect.height - 150 {
                context.beginPage()
                yPosition = margin
            }

            yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context.cgContext)
            yPosition = drawSectionTitle("Upcoming Maintenance", at: yPosition, margin: margin)

            let upcoming = horse.upcomingEvents
            if upcoming.isEmpty {
                yPosition = drawBodyText("No upcoming events scheduled.", at: yPosition, margin: margin, width: contentWidth)
            } else {
                for event in upcoming.prefix(10) {
                    if yPosition > pageRect.height - 80 {
                        context.beginPage()
                        yPosition = margin
                    }
                    yPosition = drawUpcomingRow(event, at: yPosition, margin: margin, width: contentWidth)
                }
            }

            // Analytics Section
            if yPosition > pageRect.height - 200 {
                context.beginPage()
                yPosition = margin
            }
            yPosition += 10
            yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context.cgContext)
            yPosition = drawAnalytics(horse: horse, at: yPosition, margin: margin, width: contentWidth, pageRect: pageRect, context: context)

            // Footer
            drawFooter(in: pageRect, margin: margin)
        }

        return data
    }

    // MARK: - Drawing Helpers

    private static func drawHeader(horse: Horse, in rect: CGRect, at y: CGFloat, width: CGFloat, margin: CGFloat) -> CGFloat {
        var yPos = y

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor(red: 0.13, green: 0.37, blue: 0.18, alpha: 1)
        ]
        let title = "EquineLog — Owner Report"
        title.draw(at: CGPoint(x: margin, y: yPos), withAttributes: titleAttrs)
        yPos += 34

        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.darkText
        ]
        horse.name.draw(at: CGPoint(x: margin, y: yPos), withAttributes: subtitleAttrs)
        yPos += 24

        let detailAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let details = "Owner: \(horse.ownerName) | Generated: \(dateFormatter.string(from: .now))"
        details.draw(at: CGPoint(x: margin, y: yPos), withAttributes: detailAttrs)
        yPos += 24

        return yPos
    }

    private static func drawSectionTitle(_ text: String, at y: CGFloat, margin: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1)
        ]
        text.draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
        return y + 26
    }

    private static func drawBodyText(_ text: String, at y: CGFloat, margin: CGFloat, width: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: attrs,
            context: nil
        )
        (text as NSString).draw(in: CGRect(x: margin, y: y, width: width, height: boundingRect.height), withAttributes: attrs)
        return y + boundingRect.height + 8
    }

    private static func drawEventRow(_ event: HealthEvent, at y: CGFloat, margin: CGFloat, width: CGFloat) -> CGFloat {
        var yPos = y
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        let typeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.darkText
        ]
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let notesAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let header = "\(event.type.rawValue)  —  \(dateFormatter.string(from: event.date))"
        header.draw(at: CGPoint(x: margin + 10, y: yPos), withAttributes: typeAttrs)
        yPos += 16

        if let cost = event.cost {
            let costText = String(format: "Cost: $%.2f", cost)
            costText.draw(at: CGPoint(x: margin + 10, y: yPos), withAttributes: dateAttrs)
            yPos += 14
        }

        if let provider = event.providerName, !provider.isEmpty {
            "Provider: \(provider)".draw(at: CGPoint(x: margin + 10, y: yPos), withAttributes: dateAttrs)
            yPos += 14
        }

        if !event.notes.isEmpty {
            let notesRect = CGRect(x: margin + 10, y: yPos, width: width - 20, height: 40)
            (event.notes as NSString).draw(in: notesRect, withAttributes: notesAttrs)
            yPos += 20
        }

        yPos += 8
        return yPos
    }

    private static func drawUpcomingRow(_ event: HealthEvent, at y: CGFloat, margin: CGFloat, width: CGFloat) -> CGFloat {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        let isOverdue = event.isOverdue
        let color: UIColor = isOverdue
            ? UIColor(red: 0.78, green: 0.15, blue: 0.12, alpha: 1)
            : UIColor.darkText

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: color
        ]

        let status = isOverdue ? " [OVERDUE]" : ""
        let dueDateStr = event.nextDueDate.map { dateFormatter.string(from: $0) } ?? "No date"
        let text = "\(event.type.rawValue) — Due: \(dueDateStr)\(status)"
        text.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: attrs)

        return y + 20
    }

    private static func drawAnalytics(horse: Horse, at y: CGFloat, margin: CGFloat, width: CGFloat, pageRect: CGRect, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var yPos = y
        yPos = drawSectionTitle("Analytics & Insights", at: yPos, margin: margin)

        let events = horse.healthEvents

        // Cost analysis
        let totalCost = events.compactMap(\.cost).reduce(0, +)
        let last90Days = Calendar.current.date(byAdding: .day, value: -90, to: .now)!
        let recentCost = events
            .filter { $0.date >= last90Days }
            .compactMap(\.cost)
            .reduce(0, +)

        yPos = drawBodyText("Total Recorded Costs: $\(String(format: "%.2f", totalCost))", at: yPos, margin: margin, width: width)
        yPos = drawBodyText("Last 90 Days Spend: $\(String(format: "%.2f", recentCost))", at: yPos, margin: margin, width: width)

        // Cost by category
        let costByType = Dictionary(grouping: events.filter { $0.cost != nil }, by: \.type)
        if !costByType.isEmpty {
            yPos += 4
            yPos = drawBodyText("Cost Breakdown by Category:", at: yPos, margin: margin, width: width)
            for (type, typeEvents) in costByType.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                let typeCost = typeEvents.compactMap(\.cost).reduce(0, +)
                let count = typeEvents.count
                yPos = drawBodyText(
                    "  \(type.rawValue): $\(String(format: "%.2f", typeCost)) (\(count) visit\(count == 1 ? "" : "s"))",
                    at: yPos, margin: margin, width: width
                )
            }
        }

        // Cycle compliance
        yPos += 8
        let overdueCount = horse.overdueEvents.count
        let upcomingCount = horse.upcomingEvents.count
        if overdueCount > 0 {
            yPos = drawBodyText(
                "Action Required: \(overdueCount) overdue maintenance item\(overdueCount == 1 ? "" : "s"). Staying on schedule can prevent costly emergency visits.",
                at: yPos, margin: margin, width: width
            )
        } else if upcomingCount > 0 {
            yPos = drawBodyText(
                "On Track: All maintenance is current. \(upcomingCount) upcoming item\(upcomingCount == 1 ? "" : "s") scheduled.",
                at: yPos, margin: margin, width: width
            )
        }

        // Farrier frequency insight
        let farrierEvents = events.filter { $0.type == .farrier }.sorted { $0.date < $1.date }
        if farrierEvents.count >= 2 {
            let intervals = zip(farrierEvents, farrierEvents.dropFirst()).map { pair in
                Calendar.current.dateComponents([.day], from: pair.0.date, to: pair.1.date).day ?? 0
            }
            let avgInterval = intervals.reduce(0, +) / intervals.count
            yPos += 4
            yPos = drawBodyText(
                "Farrier Cycle: Averaging \(avgInterval) days between visits (recommended: 42-56 days).",
                at: yPos, margin: margin, width: width
            )
            if avgInterval > 56 {
                yPos = drawBodyText(
                    "Consider shortening the farrier cycle. Longer intervals can lead to hoof problems and increased vet costs.",
                    at: yPos, margin: margin, width: width
                )
            }
        }

        return yPos
    }

    private static func drawDivider(at y: CGFloat, margin: CGFloat, width: CGFloat, in cgContext: CGContext) -> CGFloat {
        cgContext.setStrokeColor(UIColor(red: 0.80, green: 0.75, blue: 0.68, alpha: 1).cgColor)
        cgContext.setLineWidth(0.5)
        cgContext.move(to: CGPoint(x: margin, y: y))
        cgContext.addLine(to: CGPoint(x: margin + width, y: y))
        cgContext.strokePath()
        return y + 14
    }

    private static func drawFooter(in rect: CGRect, margin: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.lightGray
        ]
        let footer = "Generated by EquineLog | Confidential"
        footer.draw(at: CGPoint(x: margin, y: rect.height - 30), withAttributes: attrs)
    }
}

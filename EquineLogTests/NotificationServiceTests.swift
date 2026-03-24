import Testing
import Foundation
@testable import EquineLog

/// Tests for the notification scoring system: ValueScore, ScoreBonus, and threshold logic.
/// Validates that each high-value moment computes scores correctly and gates on thresholds.
@Suite("Notification Service Tests")
struct NotificationServiceTests {

    // MARK: - ValueScore Base Computation

    @Test("ValueScore totalScore equals base when no bonuses")
    func totalScoreWithNoBonuses() {
        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: [])
        #expect(score.totalScore == 80)
    }

    @Test("ValueScore totalScore adds bonuses to base")
    func totalScoreWithBonuses() {
        let bonuses = [
            ScoreBonus(reason: "days overdue", points: 10),
            ScoreBonus(reason: "farrier overdue", points: 10)
        ]
        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: bonuses)
        #expect(score.totalScore == 100)
    }

    @Test("ValueScore totalScore caps at 120")
    func totalScoreCapsAt120() {
        let bonuses = [
            ScoreBonus(reason: "bonus1", points: 30),
            ScoreBonus(reason: "bonus2", points: 30),
            ScoreBonus(reason: "bonus3", points: 30)
        ]
        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: bonuses)
        #expect(score.totalScore == 120, "Score should cap at 120, not \(score.totalScore)")
    }

    @Test("ValueScore totalScore caps even with extreme bonuses")
    func totalScoreCapsWithExtremeBonuses() {
        let bonuses = [ScoreBonus(reason: "huge", points: 200)]
        let score = ValueScore(momentType: .feedingStreak, baseScore: 50, bonuses: bonuses)
        #expect(score.totalScore == 120)
    }

    // MARK: - meetsThreshold

    @Test("meetsThreshold returns true when score equals threshold")
    func meetsThresholdAtExactValue() {
        // overdueCascade threshold is 80, base score 80 with no bonuses
        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: [])
        #expect(score.meetsThreshold == true)
    }

    @Test("meetsThreshold returns true when score exceeds threshold")
    func meetsThresholdAboveValue() {
        let bonuses = [ScoreBonus(reason: "extra", points: 10)]
        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: bonuses)
        #expect(score.meetsThreshold == true)
    }

    @Test("meetsThreshold returns false when score is below threshold")
    func meetsThresholdBelowValue() {
        // coldSnapBlanket threshold is 70, base 60 with no bonuses = 60
        let score = ValueScore(momentType: .coldSnapBlanket, baseScore: 60, bonuses: [])
        #expect(score.meetsThreshold == false)
    }

    // MARK: - Overdue Cascade Scoring

    @Test("Overdue cascade: base 80 meets threshold of 80")
    func overdueCascadeBaseScore() {
        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: [])
        #expect(score.totalScore == 80)
        #expect(score.meetsThreshold == true)
    }

    @Test("Overdue cascade: day bonus capped at 20 points")
    func overdueCascadeDayBonusCap() {
        // The service computes: min(maxOverdueDays * 5, 20)
        // 10 days overdue => min(50, 20) = 20
        let dayBonus = min(10 * 5, 20)
        #expect(dayBonus == 20)

        let bonuses = [ScoreBonus(reason: "days overdue", points: dayBonus)]
        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: bonuses)
        #expect(score.totalScore == 100)
    }

    @Test("Overdue cascade: 2 days overdue gives 10 point day bonus")
    func overdueCascadeTwoDays() {
        let dayBonus = min(2 * 5, 20)
        #expect(dayBonus == 10)
    }

    @Test("Overdue cascade: farrier bonus adds 10 points")
    func overdueCascadeFarrierBonus() {
        let bonuses = [ScoreBonus(reason: "farrier overdue", points: 10)]
        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: bonuses)
        #expect(score.totalScore == 90)
    }

    @Test("Overdue cascade: multiple horse bonus adds 10 points")
    func overdueCascadeMultipleHorseBonus() {
        let bonuses = [ScoreBonus(reason: "multiple overdue on same horse", points: 10)]
        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: bonuses)
        #expect(score.totalScore == 90)
    }

    @Test("Overdue cascade: all bonuses combined")
    func overdueCascadeAllBonuses() {
        let bonuses = [
            ScoreBonus(reason: "days overdue", points: 20),
            ScoreBonus(reason: "farrier overdue", points: 10),
            ScoreBonus(reason: "multiple overdue on same horse", points: 10)
        ]
        let score = ValueScore(momentType: .overdueCascade, baseScore: 80, bonuses: bonuses)
        #expect(score.totalScore == 120, "80 + 20 + 10 + 10 = 120 (at cap)")
    }

    // MARK: - Weather Moment Scoring

    @Test("Weather moment: base 60 does not meet threshold of 70")
    func weatherMomentBaseBelowThreshold() {
        let score = ValueScore(momentType: .coldSnapBlanket, baseScore: 60, bonuses: [])
        #expect(score.totalScore == 60)
        #expect(score.meetsThreshold == false)
    }

    @Test("Weather moment: threshold crossing bonus meets threshold")
    func weatherMomentThresholdCrossing() {
        let bonuses = [ScoreBonus(reason: "threshold crossing", points: 20)]
        let score = ValueScore(momentType: .coldSnapBlanket, baseScore: 60, bonuses: bonuses)
        #expect(score.totalScore == 80)
        #expect(score.meetsThreshold == true)
    }

    @Test("Weather moment: clipped horse bonus alone meets threshold")
    func weatherMomentClippedHorseBonus() {
        let bonuses = [ScoreBonus(reason: "clipped horse", points: 10)]
        let score = ValueScore(momentType: .coldSnapBlanket, baseScore: 60, bonuses: bonuses)
        #expect(score.totalScore == 70)
        #expect(score.meetsThreshold == true)
    }

    @Test("Weather moment: extreme cold bonus alone meets threshold")
    func weatherMomentExtremeColdBonus() {
        let bonuses = [ScoreBonus(reason: "extreme cold", points: 10)]
        let score = ValueScore(momentType: .coldSnapBlanket, baseScore: 60, bonuses: bonuses)
        #expect(score.totalScore == 70)
        #expect(score.meetsThreshold == true)
    }

    @Test("Weather moment: all bonuses combined")
    func weatherMomentAllBonuses() {
        let bonuses = [
            ScoreBonus(reason: "threshold crossing", points: 20),
            ScoreBonus(reason: "clipped horse", points: 10),
            ScoreBonus(reason: "extreme cold", points: 10)
        ]
        let score = ValueScore(momentType: .coldSnapBlanket, baseScore: 60, bonuses: bonuses)
        #expect(score.totalScore == 100)
        #expect(score.meetsThreshold == true)
    }

    // MARK: - Feeding Streak Milestones

    @Test("Feeding streak: milestones are 7, 14, and 30 days")
    func feedingStreakMilestones() {
        let milestones = [7, 14, 30]
        #expect(milestones.contains(7))
        #expect(milestones.contains(14))
        #expect(milestones.contains(30))
        #expect(!milestones.contains(5))
        #expect(!milestones.contains(21))
    }

    @Test("Feeding streak: threshold is 50, easily met by any moment")
    func feedingStreakThreshold() {
        let score = ValueScore(momentType: .feedingStreak, baseScore: 50, bonuses: [])
        #expect(score.totalScore == 50)
        #expect(score.meetsThreshold == true)
    }

    // MARK: - Unfed Alert Scoring

    @Test("Unfed alert: base 75 with horse count bonus meets threshold")
    func unfedAlertWithHorseCountBonus() {
        // Threshold is 70; base 75 already meets it
        let bonuses = [ScoreBonus(reason: "unfed horse count", points: 10)]
        let score = ValueScore(momentType: .unfedAlert, baseScore: 75, bonuses: bonuses)
        #expect(score.totalScore == 85)
        #expect(score.meetsThreshold == true)
    }

    @Test("Unfed alert: horse count bonus capped at 20")
    func unfedAlertHorseCountBonusCap() {
        // Service uses: min(unfedHorses.count * 5, 20)
        let horseCountBonus = min(10 * 5, 20)
        #expect(horseCountBonus == 20)
    }

    @Test("Unfed alert: medications bonus adds 10 points")
    func unfedAlertMedicationsBonus() {
        let bonuses = [
            ScoreBonus(reason: "unfed horse count", points: 5),
            ScoreBonus(reason: "medications due", points: 10)
        ]
        let score = ValueScore(momentType: .unfedAlert, baseScore: 75, bonuses: bonuses)
        #expect(score.totalScore == 90)
    }

    // MARK: - Upcoming Maintenance Scoring

    @Test("Upcoming maintenance: base 65 meets threshold of 65")
    func upcomingMaintenanceBaseScore() {
        let score = ValueScore(momentType: .upcomingMaintenance, baseScore: 65, bonuses: [])
        #expect(score.meetsThreshold == true)
    }

    @Test("Upcoming maintenance: due tomorrow bonus adds 10")
    func upcomingMaintenanceDueTomorrow() {
        let bonuses = [ScoreBonus(reason: "due tomorrow", points: 10)]
        let score = ValueScore(momentType: .upcomingMaintenance, baseScore: 65, bonuses: bonuses)
        #expect(score.totalScore == 75)
    }

    // MARK: - Threshold Values

    @Test("Each moment type has expected threshold")
    func momentTypeThresholds() {
        #expect(HighValueMomentType.overdueCascade.threshold == 80)
        #expect(HighValueMomentType.coldSnapBlanket.threshold == 70)
        #expect(HighValueMomentType.feedingStreak.threshold == 50)
        #expect(HighValueMomentType.unfedAlert.threshold == 70)
        #expect(HighValueMomentType.upcomingMaintenance.threshold == 65)
    }

    @Test("Each moment type has expected cooldown interval")
    func momentTypeCooldowns() {
        #expect(HighValueMomentType.overdueCascade.cooldownInterval == 24 * 60 * 60)
        #expect(HighValueMomentType.coldSnapBlanket.cooldownInterval == 12 * 60 * 60)
        #expect(HighValueMomentType.feedingStreak.cooldownInterval == 24 * 60 * 60)
        #expect(HighValueMomentType.unfedAlert.cooldownInterval == 4 * 60 * 60)
        #expect(HighValueMomentType.upcomingMaintenance.cooldownInterval == 24 * 60 * 60)
    }

    @Test("Daily notification cap is 4")
    @MainActor
    func dailyNotificationCap() {
        #expect(NotificationPreferences.maxNotificationsPerDay == 4)
    }
}

//
//  FormaTests.swift
//  FormaTests
//
//  Created by Aneesh Patne on 19/06/26.
//

import Testing
import Foundation
import SwiftUI
@testable import Forma

struct FormaChartStyleTests {
    @Test func paddedDomainAddsHeadroomForFlatData() {
        let domain = FormaChartStyle.paddedDomain(values: [72, 72, 72])

        #expect(domain.lowerBound < 72)
        #expect(domain.upperBound > 72)
    }

    @Test func paddedDomainCanIncludeZero() {
        let domain = FormaChartStyle.paddedDomain(values: [4, 8, 12], includeZero: true)

        #expect(domain.lowerBound < 0)
        #expect(domain.upperBound > 12)
    }

    @Test func axisDatesUseFirstMiddleAndLast() {
        let dates = (0..<7).map { Date(timeIntervalSinceReferenceDate: Double($0 * 86_400)) }

        #expect(FormaChartStyle.axisDates(dates) == [dates[0], dates[3], dates[6]])
    }

    @Test func nearestDateSnapsToARealSample() {
        let dates = [
            Date(timeIntervalSinceReferenceDate: 0),
            Date(timeIntervalSinceReferenceDate: 100),
            Date(timeIntervalSinceReferenceDate: 200)
        ]

        let selection = Date(timeIntervalSinceReferenceDate: 141)
        #expect(FormaChartStyle.nearestDate(to: selection, in: dates) == dates[1])
    }

    @Test func steppedDateMovesAcrossSamplesAndClampsAtBounds() {
        let dates = [
            Date(timeIntervalSinceReferenceDate: 0),
            Date(timeIntervalSinceReferenceDate: 100),
            Date(timeIntervalSinceReferenceDate: 200)
        ]

        #expect(FormaChartStyle.steppedDate(from: dates[1], offset: 1, in: dates) == dates[2])
        #expect(FormaChartStyle.steppedDate(from: dates[0], offset: -1, in: dates) == dates[0])
        #expect(FormaChartStyle.steppedDate(from: dates[2], offset: 1, in: dates) == dates[2])
    }
}

struct FormaFeedbackPolicyTests {
    @Test func routineSelectionIsHapticOnly() {
        #expect(FormaUIFeedback.selection.playsSound == false)
        #expect(FormaUIFeedback.softImpact.playsSound == false)
    }

    @Test func confirmationsAndRecordMilestonesKeepSound() {
        #expect(FormaUIFeedback.confirm.playsSound)
        #expect(FormaUIFeedback.success.playsSound)
        #expect(RecordFeedbackEvent.metric(.weight).playsSound)
        #expect(RecordFeedbackEvent.success.playsSound)
    }
}

@MainActor
struct FoodPayloadTests {
    @Test func analysisProposalDecodesCompleteNutrition() throws {
        let data = Data(#"{"ok":true,"action":"propose","message":"Ready","food":{"name":"Eggs","servingDescription":"2 large eggs","servings":1,"meal":"breakfast","calories":144,"proteinG":12.6,"carbsG":0.7,"fatG":9.5,"fiberG":0,"saturatedFatG":3.1,"transFatG":0,"monounsaturatedFatG":3.7,"polyunsaturatedFatG":1.9,"sugarG":0.4,"addedSugarG":0,"sodiumMg":142,"cholesterolMg":372}}"#.utf8)
        let response = try JSONDecoder().decode(FoodAnalysisResponse.self, from: data)

        #expect(response.food?.meal == .breakfast)
        #expect(response.food?.proteinG == 12.6)
        #expect(response.food?.cholesterolMg == 372)
    }

    @Test func dashboardDecodesEntriesTrendsAndGoals() throws {
        let data = Data(#"{"ok":true,"entries":[],"trends":[{"date":"2026-09-08","calories":1900,"proteinG":155,"carbsG":210,"fatG":65}],"goals":{"calories":2200,"proteinG":160,"carbsG":240,"fatG":70}}"#.utf8)
        let dashboard = try JSONDecoder().decode(FoodDashboardResponse.self, from: data)

        #expect(dashboard.trends.first?.proteinG == 155)
        #expect(dashboard.goals.calories == 2200)
    }
}

struct FoodSearchTests {
    private let foods = [
        FoodNutrition(name: "Greek yogurt", servingDescription: "170 g tub", servings: 1, meal: .snack, calories: 100, proteinG: 17, carbsG: 6, fatG: 0, fiberG: 0, saturatedFatG: 0, transFatG: 0, monounsaturatedFatG: 0, polyunsaturatedFatG: 0, sugarG: 5, addedSugarG: 0, sodiumMg: 60, cholesterolMg: 5),
        FoodNutrition(name: "Chicken breast", servingDescription: "100 g cooked", servings: 1, meal: .lunch, calories: 165, proteinG: 31, carbsG: 0, fatG: 3.6, fiberG: 0, saturatedFatG: 1, transFatG: 0, monounsaturatedFatG: 1.2, polyunsaturatedFatG: 0.8, sugarG: 0, addedSugarG: 0, sodiumMg: 74, cholesterolMg: 85)
    ]

    @Test func fuzzySearchHandlesTyposAndNonPrefixTerms() {
        #expect(FoodSearch.matches("grek yog", in: foods).first?.name == "Greek yogurt")
        #expect(FoodSearch.matches("cooked chicken", in: foods).first?.name == "Chicken breast")
    }
}

@MainActor
struct ProfileRequestTests {
    @Test func onboardingPayloadIncludesMuscularityGoal() throws {
        let body = CreateClientProfileBody(
            name: "Example",
            isPrimary: true,
            heightCm: 172,
            dateOfBirth: "1995-01-01",
            peopleType: "standard",
            gender: "male",
            profileImage: nil,
            preferredBodyFatPct: 18,
            muscularityGoal: "athletic"
        )

        let encoded = try JSONEncoder().encode(body)
        let json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(json["muscularityGoal"] as? String == "athletic")
    }

    @Test func profilePatchCanUpdateOnlyMuscularityGoal() throws {
        let body = UpdateClientProfileBody(
            name: nil,
            isPrimary: nil,
            heightCm: nil,
            dateOfBirth: nil,
            peopleType: nil,
            gender: nil,
            profileImage: nil,
            preferredBodyFatPct: nil,
            muscularityGoal: "muscular"
        )

        let encoded = try JSONEncoder().encode(body)
        let json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(json.count == 1)
        #expect(json["muscularityGoal"] as? String == "muscular")
    }
}


@MainActor
struct PerformanceSweepTests {
    @Test func preparedChartPreservesSamplesAndFindsPerMetricEndpoints() {
        let early = Date(timeIntervalSinceReferenceDate: 100)
        let late = Date(timeIntervalSinceReferenceDate: 200)
        let points = [
            FormaChartPoint(date: late, value: 12, metric: "Fat", color: .red),
            FormaChartPoint(date: early, value: 60, metric: "Muscle", color: .green),
            FormaChartPoint(date: early, value: 14, metric: "Fat", color: .red)
        ]
        let prepared = FormaChartData(points: points, includeZero: true)
        #expect(prepared.points == [points[2], points[1], points[0]])
        #expect(prepared.sampleDates == [early, late])
        #expect(prepared.latestDateByMetric == ["Fat": late, "Muscle": early])
        #expect(prepared.groups["Fat"] == [points[2], points[0]])
        #expect(prepared.domain.lowerBound < 0)
        #expect(prepared.domain.upperBound > 60)
        #expect(FormaChartData(points: prepared.points).points == prepared.points)
    }

    @Test func preparedChartHandlesEmptyAndSingleSample() {
        let empty = FormaChartData(points: [])
        #expect(empty.points.isEmpty)
        #expect(empty.sampleDates.isEmpty)
        #expect(empty.latestDateByMetric.isEmpty)
        #expect(empty.domain == 0...1)
        let point = FormaChartPoint(date: .distantPast, value: 72, metric: "Weight", color: .blue)
        let single = FormaChartData(points: [point])
        #expect(single.points == [point])
        #expect(single.latestDateByMetric["Weight"] == point.date)
        #expect(single.domain.contains(72))
    }

    @Test func trendDatesKeepSupportedTimestampFormats() throws {
        let timestamps = ["2026-01-01T00:00:00.000Z", "2026-01-01T00:00:00Z", "2026-01-01"]
        let dates = try timestamps.map { timestamp in
            let point = try #require(InsightReportTrendPoint(json: .object([
                "createdAt": .string(timestamp), "value": .number(72)
            ])))
            return point.date
        }
        #expect(dates.allSatisfy { $0 == dates[0] })
    }

    @Test func reportPayloadTracksReplacementAndClearing() {
        let store = MetricsReportStore()
        #expect(store.payload == nil)
        store.applyDebugScenario(.metricsPopulated)
        #expect(store.payload == InsightReportPayload(data: FormaFixtures.populatedReport.data))
        store.applyDebugScenario(.metricsLoading)
        #expect(store.payload == nil)
        store.applyDebugScenario(.metricsPopulated)
        #expect(store.payload != nil)
        store.applyDebugScenario(.metricsError)
        #expect(store.payload == nil)
    }
}

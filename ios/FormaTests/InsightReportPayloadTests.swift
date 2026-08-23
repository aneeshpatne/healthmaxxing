import Foundation
import Testing
@testable import Forma

struct InsightReportPayloadTests {
    @Test func reportRoundTripsForPersistentCache() throws {
        let report = InsightReport(
            reportId: UUID(),
            profileId: UUID(),
            generationStatus: "completed",
            generationError: nil,
            createdAt: "2026-07-14T10:00:00Z",
            updatedAt: "2026-07-14T10:05:00Z",
            data: .object([
                "score": .number(87.5),
                "summary": .string("Consistent progress"),
                "ready": .bool(true),
                "tags": .array([.string("strength"), .null])
            ])
        )

        let encoded = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(InsightReport.self, from: encoded)

        #expect(decoded == report)
    }

    @Test func parsesUpdatedBodyFatAndMuscleTrends() {
        let payload = InsightReportPayload(data: .object([
            "fat": .object([
                "fat_ratio": metricSection(value: 24.5, trends: [
                    "fatPercent": trendPoint(value: 24.5)
                ]),
                "fat_ratio_trend": metricSection(value: 21.6, trends: [
                    "fatPercent": trendPoint(value: 21.6)
                ])
            ]),
            "muscle": .object([
                "skeletal_muscle_gauge": .object([
                    "heading": .string("Skeletal Muscle"),
                    "title": .string("Ratio"),
                    "comment": .string("Solid muscle density."),
                    "factor_color": .string("green"),
                    "remark": .object([
                        "marker": .string("complement"),
                        "text": .string("Keep training.")
                    ]),
                    "preprocess": .object([
                        "value": .number(38.89)
                    ])
                ]),
                "muscle_mass": metricSection(trends: [
                    "muscleMassKg": trendPoint(value: 42)
                ]),
                "muscle_ratio_trend": metricSection(
                    value: 56,
                    trends: ["muscleRatio": trendPoint(value: 56)]
                )
            ])
        ]))

        #expect(payload?.fat["fat_ratio"]?.numberValue == 24.5)
        #expect(payload?.fat["fat_ratio"]?.trends["fatPercent"]?.first?.value == 24.5)
        #expect(payload?.fat["fat_ratio_trend"]?.numberValue == 21.6)
        #expect(payload?.fat["fat_ratio_trend"]?.trends["fatPercent"]?.first?.value == 21.6)
        #expect(payload?.muscle["skeletal_muscle_gauge"]?.numberValue == 38.89)
        #expect(payload?.muscle["skeletal_muscle_gauge"]?.factorColor == .green)
        #expect(payload?.muscle["muscle_mass"]?.trends["muscleMassKg"]?.first?.value == 42)
        #expect(payload?.muscle["muscle_ratio_trend"]?.trends["muscleRatio"]?.first?.value == 56)
        #expect(payload?.muscle["muscle_mass_trend"] == nil)

        let date = payload?.fat["fat_ratio_trend"]?.trends["fatPercent"]?.first?.date ?? .distantPast
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2026)
        #expect(components.month == 6)
        #expect(components.day == 1)
    }

    @Test func parsesInsightsMomentumFactorAndLeanFatFlow() {
        let payload = InsightReportPayload(data: .object([
            "insights": .object([
                "momentum": .object([
                    "title": .string("Momentum"),
                    "headline": .string("Still moving"),
                    "comment": .string("Consistency is holding."),
                    "remark": .object([
                        "marker": .string("trend_up"),
                        "text": .string("Keep the streak.")
                    ])
                ]),
                "factor": .object([
                    "factor": .string("body_fat_pct"),
                    "comment": .string("Primary lever this week."),
                    "remark": .object([
                        "marker": .string("ai_recommendation"),
                        "text": .string("Prioritize fat loss.")
                    ]),
                    "preprocess": .object([
                        "value": .number(21.5)
                    ])
                ])
            ]),
            "performance": .object([
                "body_composition_flow": .object([
                    "heading": .string("Composition"),
                    "title": .string("Lean vs fat"),
                    "comment": .string("Balanced split."),
                    "remark": .object([
                        "marker": .string("complement"),
                        "text": .string("Lean mass is solid.")
                    ]),
                    "preprocess": .object([
                        "value": .object([
                            "leanMassKg": .number(57.75),
                            "fatMassKg": .number(19.0)
                        ])
                    ])
                ])
            ])
        ]))

        #expect(payload?.momentum?.title == "Momentum")
        #expect(payload?.momentum?.remark?.marker == .trendUp)
        #expect(payload?.factor?.factor == "body_fat_pct")
        #expect(payload?.factor?.value == 21.5)
        #expect(payload?.performance["body_composition_flow"]?.nestedNumber("leanMassKg") == 57.75)
        #expect(payload?.performance["body_composition_flow"]?.nestedNumber("fatMassKg") == 19.0)
        #expect(payload?.performance["body_composition_flow"]?.nestedNumber("totalWeightKg") == nil)
    }

    private func metricSection(
        value: Double? = nil,
        trends: [String: JSONValue]
    ) -> JSONValue {
        var preprocess: [String: JSONValue] = ["trends": .object(trends)]
        if let value {
            preprocess["value"] = .number(value)
        }

        return .object(["preprocess": .object(preprocess)])
    }

    private func trendPoint(value: Double) -> JSONValue {
        .array([
            .object([
                "createdAt": .string("2026-06-01"),
                "value": .number(value)
            ])
        ])
    }
}

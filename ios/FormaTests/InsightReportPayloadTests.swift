import Foundation
import Testing
@testable import Forma

struct InsightReportPayloadTests {
    @Test func parsesUpdatedBodyFatAndMuscleTrends() {
        let payload = InsightReportPayload(data: .object([
            "fat": .object([
                "fat_ratio": metricSection(trends: [
                    "fatPercent": trendPoint(value: 24.5)
                ]),
                "fat_ratio_trend": metricSection(value: 21.6, trends: [
                    "fatPercent": trendPoint(value: 21.6)
                ])
            ]),
            "muscle": .object([
                "muscle_mass": metricSection(trends: [
                    "muscleMassKg": trendPoint(value: 42)
                ]),
                "muscle_ratio_trend": metricSection(
                    value: 56,
                    trends: ["muscleRatio": trendPoint(value: 56)]
                )
            ])
        ]))

        #expect(payload?.fat["fat_ratio"]?.trends["fatPercent"]?.first?.value == 24.5)
        #expect(payload?.fat["fat_ratio_trend"]?.numberValue == 21.6)
        #expect(payload?.fat["fat_ratio_trend"]?.trends["fatPercent"]?.first?.value == 21.6)
        #expect(payload?.muscle["muscle_mass"]?.trends["muscleMassKg"]?.first?.value == 42)
        #expect(payload?.muscle["muscle_ratio_trend"]?.trends["muscleRatio"]?.first?.value == 56)
        #expect(payload?.muscle["muscle_mass_trend"] == nil)

        let date = payload?.fat["fat_ratio_trend"]?.trends["fatPercent"]?.first?.date ?? .distantPast
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2026)
        #expect(components.month == 6)
        #expect(components.day == 1)
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

//
//  InsightReportPayload.swift
//  Forma
//
//  Created by Codex on 01/07/26.
//

import Foundation
import SwiftUI

enum RemarkMarker: String, Codable, Equatable {
    case trendUp = "trend_up"
    case trendDown = "trend_down"
    case aiRecommendation = "ai_recommendation"
    case caution = "caution"
    case complement = "complement"

    var iconName: String {
        switch self {
        case .trendUp:
            return "arrow.up.forward.circle.fill"
        case .trendDown:
            return "arrow.down.forward.circle.fill"
        case .aiRecommendation:
            return "sparkle"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .complement:
            return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .trendUp:
            return .formaTeal
        case .trendDown:
            return .formaCoral
        case .aiRecommendation:
            return .formaCyan
        case .caution:
            return .formaAmber
        case .complement:
            return .formaTeal
        }
    }

    var displayRemarkMarker: String {
        rawValue.displayRemarkMarker
    }
}

enum FactorColor: String, Codable, Equatable {
    case red
    case orange
    case yellow
    case green

    var color: Color {
        switch self {
        case .red: return .formaCoral
        case .orange: return .formaAmber
        case .yellow: return .formaYellow
        case .green: return .formaTeal
        }
    }
}

enum BodyType: String, Codable, Equatable {
    case muscular
    case fit
    case normal
    case skinnyFat = "skinny fat"
    case overweight
    case obese

    var displayName: String { rawValue.capitalized }
}


struct InsightReportPayload: Equatable {
    let overview: InsightReportSection?
    let foundation: InsightReportSection?
    let momentum: InsightReportSection?
    let progress: InsightReportProgressSection?
    let lever: InsightReportSection?
    let factor: InsightReportFactorSection?
    let physiqueArchetype: InsightReportPhysiqueSection?
    let effortScore: InsightReportEffortScoreSection?
    let performance: [String: InsightReportMetricSection]
    let fat: [String: InsightReportMetricSection]
    let muscle: [String: InsightReportMetricSection]

    init?(data: JSONValue?) {
        guard let root = data?.objectValue else {
            return nil
        }

        let insights = root["insights"]?.objectValue ?? [:]
        self.overview = InsightReportSection(json: insights["overview"])
        self.foundation = InsightReportSection(json: insights["foundation"])
        self.momentum = InsightReportSection(json: insights["momentum"])
        self.progress = InsightReportProgressSection(json: insights["progress"])
        self.lever = InsightReportSection(json: insights["lever"])
        self.factor = InsightReportFactorSection(json: insights["factor"])
        self.physiqueArchetype = InsightReportPhysiqueSection(json: insights["physique_archetype"])
        self.effortScore = InsightReportEffortScoreSection(json: insights["effort_score"])
        self.performance = Self.metricSections(from: root["performance"])
        self.fat = Self.metricSections(from: root["fat"])
        self.muscle = Self.metricSections(from: root["muscle"])
    }

    private static func metricSections(from json: JSONValue?) -> [String: InsightReportMetricSection] {
        (json?.objectValue ?? [:]).compactMapValues(InsightReportMetricSection.init(json:))
    }
}

struct InsightReportFactorSection: Equatable {
    let factor: String?
    let factorColor: FactorColor?
    let comment: String?
    let remark: InsightReportRemark?
    let value: Double?

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else { return nil }
        self.factor = object["factor"]?.stringValue
        self.factorColor = object["factor_color"]?.stringValue.flatMap(FactorColor.init(rawValue:))
        self.comment = object["comment"]?.stringValue
        self.remark = InsightReportRemark(json: object["remark"])
        self.value = object["preprocess"]?.objectValue?["value"]?.numberValue
    }
}

struct InsightReportSection: Equatable {
    let title: String?
    let headline: String?
    let comment: String?
    let remark: InsightReportRemark?

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else {
            return nil
        }

        self.title = object["title"]?.stringValue
        self.headline = object["headline"]?.stringValue
        self.comment = object["comment"]?.stringValue
        self.remark = InsightReportRemark(json: object["remark"])
    }
}

struct InsightReportProgressSection: Equatable {
    let title: String?
    let headline: String?
    let comment: String?
    let remark: InsightReportRemark?
    let trends: [String]
    let trendData: [String: [InsightReportTrendPoint]]

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else {
            return nil
        }

        self.title = object["title"]?.stringValue
        self.headline = object["headline"]?.stringValue
        self.comment = object["comment"]?.stringValue
        self.remark = InsightReportRemark(json: object["remark"])
        self.trends = object["trends"]?.arrayValue?.compactMap(\.stringValue) ?? []
        self.trendData = InsightReportMetricSection.trendSections(from: object["preprocess"]?.objectValue?["trends"])
    }
}

struct InsightReportPhysiqueSection: Equatable {
    let title: String?
    let headline: String?
    let comment: String?
    let bodyType: BodyType?

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else {
            return nil
        }

        self.title = object["title"]?.stringValue
        self.headline = object["headline"]?.stringValue
        self.comment = object["comment"]?.stringValue
        self.bodyType = object["body_type"]?.stringValue.flatMap(BodyType.init(rawValue:))
    }
}

struct InsightReportEffortScoreSection: Equatable {
    let title: String?
    let headline: String?
    let score: Double?
    let comment: String?
    let remark: InsightReportRemark?

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else {
            return nil
        }

        self.title = object["title"]?.stringValue
        self.headline = object["headline"]?.stringValue
        self.score = object["score"]?.numberValue
        self.comment = object["comment"]?.stringValue
        self.remark = InsightReportRemark(json: object["remark"])
    }
}

struct InsightReportRemark: Equatable {
    let marker: RemarkMarker?
    let text: String?

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else {
            return nil
        }

        if let markerStr = object["marker"]?.stringValue {
            self.marker = RemarkMarker(rawValue: markerStr)
        } else {
            self.marker = nil
        }
        self.text = object["text"]?.stringValue
    }
}

struct InsightReportMetricSection: Equatable {
    let heading: String?
    let title: String?
    let headline: String?
    let comment: String?
    let remark: InsightReportRemark?
    let factorColor: FactorColor?
    let value: JSONValue?
    let trends: [String: [InsightReportTrendPoint]]

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else {
            return nil
        }

        self.heading = object["heading"]?.stringValue
        self.title = object["title"]?.stringValue
        self.headline = object["headline"]?.stringValue
        self.comment = object["comment"]?.stringValue
        self.remark = InsightReportRemark(json: object["remark"])
        self.factorColor = object["factor_color"]?.stringValue.flatMap(FactorColor.init(rawValue:))
        self.value = object["preprocess"]?.objectValue?["value"]
        self.trends = Self.trendSections(from: object["preprocess"]?.objectValue?["trends"])
    }

    var displayTitle: String {
        heading ?? title ?? headline ?? "Report"
    }

    var displayComment: String {
        comment ?? remark?.text ?? headline ?? ""
    }

    var numberValue: Double? {
        value?.numberValue
    }

    func nestedNumber(_ key: String) -> Double? {
        value?.objectValue?[key]?.numberValue
    }

    func nestedNumber(_ firstKey: String, _ secondKey: String) -> Double? {
        value?.objectValue?[firstKey]?.objectValue?[secondKey]?.numberValue
    }

    static func trendSections(from json: JSONValue?) -> [String: [InsightReportTrendPoint]] {
        (json?.objectValue ?? [:]).compactMapValues { value in
            value.arrayValue?.compactMap(InsightReportTrendPoint.init(json:))
        }
    }
}

struct InsightReportTrendPoint: Equatable {
    let createdAt: String
    let value: Double

    init?(json: JSONValue) {
        guard let object = json.objectValue,
              let createdAt = object["createdAt"]?.stringValue,
              let value = object["value"]?.numberValue else {
            return nil
        }

        self.createdAt = createdAt
        self.value = value
    }

    var date: Date {
        ISO8601DateFormatter.reportDateFormatter.date(from: createdAt)
            ?? ISO8601DateFormatter.reportDateFormatterWithoutFractions.date(from: createdAt)
            ?? ISO8601DateFormatter.reportDateFormatterDateOnly.date(from: createdAt)
            ?? Date()
    }

    var shortDate: String {
        Self.shortDateFormatter.string(from: date)
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

private extension ISO8601DateFormatter {
    static let reportDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let reportDateFormatterWithoutFractions: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let reportDateFormatterDateOnly: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}

extension JSONValue {
    var objectValue: [String: JSONValue]? {
        if case .object(let object) = self {
            return object
        }

        return nil
    }

    var arrayValue: [JSONValue]? {
        if case .array(let array) = self {
            return array
        }

        return nil
    }

    var stringValue: String? {
        if case .string(let string) = self {
            return string
        }

        return nil
    }

    var numberValue: Double? {
        if case .number(let number) = self {
            return number.isFinite ? number : nil
        }

        return nil
    }
}

extension String {
    var displayRemarkMarker: String {
        split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    var displayTrendLabel: String {
        switch self {
        case "body_fat_pct", "fatPercent":
            return "Body Fat"
        case "fat_mass_kg", "fatMassKg", "fatMass30Days":
            return "Fat Mass"
        case "leanMass30Days":
            return "Lean Mass"
        case "muscle_mass_kg", "muscleMassKg", "muscleRatio":
            return "Muscle Mass"
        case "visceralFatIndex", "visceralFatMassKg", "visceralFatPercent", "visceral_fat":
            return "Visceral Fat"
        case "subcutaneousFatMassKg", "subcutaneousFatPercent", "subcutaneous_fat_mass_kg", "subcutaneous_fat_pct":
            return "Subcutaneous Fat"
        case "leanNonMuscleMassKg", "boneMassKg":
            // Server renamed bone mass → lean non-muscle mass.
            return "Lean Non-Muscle"
        case "skeletalMuscleMassKg", "skeletalMuscleRatio", "skeletal_muscle_kg":
            return "Skeletal Muscle"
        case "muscle_rate_pct":
            return "Muscle Rate"
        default:
            return displayRemarkMarker
        }
    }
}

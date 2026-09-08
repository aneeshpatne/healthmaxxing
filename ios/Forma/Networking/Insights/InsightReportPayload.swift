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
            return .formaPositive
        case .trendDown:
            return .formaNegative
        case .aiRecommendation:
            return .formaInfo
        case .caution:
            return .formaCaution
        case .complement:
            return .formaPositive
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
        case .red: return .formaNegative
        case .orange: return .formaCaution
        case .yellow: return .formaCaution
        case .green: return .formaPositive
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
    let keyTrend: InsightReportKeyTrendSection?
    let physiqueArchetype: InsightReportPhysiqueSection?
    let effortScore: InsightReportEffortScoreSection?
    let performance: [String: InsightReportMetricSection]
    let fat: [String: InsightReportMetricSection]
    let muscle: [String: InsightReportMetricSection]
    let usesNewInsightsShape: Bool

    init?(data: JSONValue?) {
        guard let root = data?.objectValue,
              Self.hasValidSchema(root) else {
            return nil
        }

        let insights = root["insights"]?.objectValue ?? [:]
        self.usesNewInsightsShape = insights["factor"] != nil
            && insights["key_trend"] != nil
            && insights["progress"] != nil
        self.overview = InsightReportSection(json: insights["overview"])
        self.foundation = InsightReportSection(json: insights["foundation"])
        self.momentum = InsightReportSection(json: insights["momentum"])
        self.progress = InsightReportProgressSection(json: insights["progress"])
        self.lever = InsightReportSection(json: insights["lever"])
        self.factor = InsightReportFactorSection(json: insights["factor"])
        self.keyTrend = InsightReportKeyTrendSection(json: insights["key_trend"])
        self.physiqueArchetype = InsightReportPhysiqueSection(json: insights["physique_archetype"])
        self.effortScore = InsightReportEffortScoreSection(json: insights["effort_score"])
        self.performance = Self.metricSections(from: root["performance"])
        self.fat = Self.metricSections(from: root["fat"])
        self.muscle = Self.metricSections(from: root["muscle"])
    }

    private static func metricSections(from json: JSONValue?) -> [String: InsightReportMetricSection] {
        (json?.objectValue ?? [:]).compactMapValues(InsightReportMetricSection.init(json:))
    }

    private static func hasValidSchema(_ root: [String: JSONValue]) -> Bool {
        let sectionKeys = ["insights", "performance", "fat", "muscle"]
        guard sectionKeys.contains(where: { root[$0] != nil }) else { return false }

        for key in sectionKeys {
            guard let section = root[key] else { continue }
            guard let object = section.objectValue else { return false }

            if key == "insights" {
                guard object.values.allSatisfy({ validateInsightSection($0) }) else { return false }
            } else {
                guard object.values.allSatisfy({ validateMetricSection($0) }) else { return false }
            }
        }

        if let insights = root["insights"]?.objectValue {
            let hasNewShape = insights["factor"] != nil
                && insights["key_trend"] != nil
                && insights["progress"] != nil
            if insights["key_trend"] != nil && !hasNewShape { return false }
            if hasNewShape && !validateNewInsights(insights) { return false }
        }

        return true
    }

    private static let insightTrendMetrics: Set<String> = [
        "body_fat_pct",
        "fat_mass_kg",
        "muscle_mass_kg",
        "skeletal_muscle_kg",
        "visceral_fat",
        "subcutaneous_fat_mass_kg"
    ]

    private static func validateNewInsights(_ insights: [String: JSONValue]) -> Bool {
        guard let factor = insights["factor"]?.objectValue,
              factor["factor"]?.stringValue != nil,
              factor["comment"]?.stringValue != nil,
              validateRequiredFactorColor(factor["factor_color"]),
              validateRequiredRemark(factor["remark"]),
              let factorPreprocess = factor["preprocess"]?.objectValue,
              validateEvidence(factorPreprocess["evidence"]),
              let keyTrend = insights["key_trend"]?.objectValue,
              validateNarrativeFields(keyTrend),
              validateRequiredRemark(keyTrend["remark"]),
              let metric = keyTrend["metric"]?.stringValue,
              insightTrendMetrics.contains(metric),
              let keyTrendPreprocess = keyTrend["preprocess"]?.objectValue,
              validateSelectedTrends(keyTrendPreprocess["trends"], allowedMetrics: [metric], maximumCount: 1),
              validateEvidence(keyTrendPreprocess["evidence"]),
              let progress = insights["progress"]?.objectValue,
              validateNarrativeFields(progress),
              validateRequiredRemark(progress["remark"]),
              let selectedMetricValues = progress["trends"]?.arrayValue,
              selectedMetricValues.allSatisfy({ $0.stringValue != nil }),
              (1...3).contains(selectedMetricValues.count),
              Set(selectedMetricValues.compactMap(\.stringValue)).count == selectedMetricValues.count,
              selectedMetricValues.compactMap(\.stringValue).allSatisfy({ insightTrendMetrics.contains($0) }),
              let progressPreprocess = progress["preprocess"]?.objectValue,
              validateSelectedTrends(
                progressPreprocess["trends"],
                allowedMetrics: Set(selectedMetricValues.compactMap(\.stringValue)),
                maximumCount: 3
              ),
              validateEvidence(progressPreprocess["evidence"])
        else { return false }

        return true
    }

    private static func validateNarrativeFields(_ object: [String: JSONValue]) -> Bool {
        object["title"]?.stringValue != nil
            && object["headline"]?.stringValue != nil
            && object["comment"]?.stringValue != nil
    }

    private static func validateRequiredFactorColor(_ json: JSONValue?) -> Bool {
        guard let color = json?.stringValue else { return false }
        return FactorColor(rawValue: color) != nil
    }

    private static func validateRequiredRemark(_ json: JSONValue?) -> Bool {
        guard let object = json?.objectValue,
              let marker = object["marker"]?.stringValue,
              RemarkMarker(rawValue: marker) != nil,
              validateRequiredFactorColor(object["factor_color"]),
              object["text"]?.stringValue != nil else { return false }
        return true
    }

    private static func validateEvidence(_ json: JSONValue?) -> Bool {
        guard let json else { return true }
        guard let object = json.objectValue,
              object["asOf"]?.stringValue != nil,
              let readingCount = object["readingCount"]?.numberValue,
              readingCount >= 0,
              readingCount.rounded() == readingCount,
              let confidence = object["confidence"]?.stringValue,
              ["low", "medium", "high"].contains(confidence) else { return false }
        if let periodStart = object["periodStart"], periodStart != .null, periodStart.stringValue == nil {
            return false
        }
        if let periodEnd = object["periodEnd"], periodEnd.stringValue == nil { return false }
        return true
    }

    private static func validateSelectedTrends(
        _ json: JSONValue?,
        allowedMetrics: Set<String>,
        maximumCount: Int
    ) -> Bool {
        guard let trends = json?.objectValue,
              !trends.isEmpty,
              trends.count <= maximumCount,
              Set(trends.keys).isSubset(of: allowedMetrics) else { return false }
        return validateTrends(in: json)
    }

    private static func validateInsightSection(_ json: JSONValue) -> Bool {
        guard let object = json.objectValue else { return false }

        guard validateRemark(object["remark"]) else { return false }
        if let colorJSON = object["factor_color"], colorJSON != .null {
            guard let color = colorJSON.stringValue,
                  FactorColor(rawValue: color) != nil else { return false }
        }
        if let bodyTypeJSON = object["body_type"], bodyTypeJSON != .null {
            guard let bodyType = bodyTypeJSON.stringValue,
                  BodyType(rawValue: bodyType) != nil else { return false }
        }
        if let preprocess = object["preprocess"], preprocess.objectValue == nil {
            return false
        }

        return validateTrends(in: object["preprocess"]?.objectValue?["trends"])
    }

    private static func validateMetricSection(_ json: JSONValue) -> Bool {
        guard let object = json.objectValue else { return false }

        guard validateRemark(object["remark"]) else { return false }
        if let colorJSON = object["factor_color"], colorJSON != .null {
            guard let color = colorJSON.stringValue,
                  FactorColor(rawValue: color) != nil else { return false }
        }
        if let preprocess = object["preprocess"], preprocess.objectValue == nil {
            return false
        }

        return validateTrends(in: object["preprocess"]?.objectValue?["trends"])
    }

    private static func validateRemark(_ json: JSONValue?) -> Bool {
        guard let json else { return true }
        if case .null = json { return true }
        guard let remark = json.objectValue else { return false }
        guard let markerJSON = remark["marker"] else { return true }
        guard let marker = markerJSON.stringValue else { return false }
        return RemarkMarker(rawValue: marker) != nil
    }

    private static func validateTrends(in json: JSONValue?) -> Bool {
        guard let json else { return true }
        guard let trends = json.objectValue else { return false }

        return trends.values.allSatisfy { trend in
            guard let points = trend.arrayValue else { return false }
            return points.allSatisfy { point in
                guard let object = point.objectValue else { return false }
                return object["createdAt"]?.stringValue != nil
                    && object["value"]?.numberValue != nil
            }
        }
    }
}

struct InsightReportFactorSection: Equatable {
    let factor: String?
    let factorColor: FactorColor?
    let comment: String?
    let remark: InsightReportRemark?
    let value: Double?
    let evidence: InsightReportEvidence?

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else { return nil }
        self.factor = object["factor"]?.stringValue
        self.factorColor = object["factor_color"]?.stringValue.flatMap(FactorColor.init(rawValue:))
        self.comment = object["comment"]?.stringValue
        self.remark = InsightReportRemark(json: object["remark"])
        self.value = object["preprocess"]?.objectValue?["value"]?.numberValue
        self.evidence = InsightReportEvidence(json: object["preprocess"]?.objectValue?["evidence"])
    }
}

struct InsightReportKeyTrendSection: Equatable {
    let title: String?
    let headline: String?
    let comment: String?
    let remark: InsightReportRemark?
    let metric: String?
    let trendData: [String: [InsightReportTrendPoint]]
    let evidence: InsightReportEvidence?

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else { return nil }
        self.title = object["title"]?.stringValue
        self.headline = object["headline"]?.stringValue
        self.comment = object["comment"]?.stringValue
        self.remark = InsightReportRemark(json: object["remark"])
        self.metric = object["metric"]?.stringValue
        self.trendData = InsightReportMetricSection.trendSections(
            from: object["preprocess"]?.objectValue?["trends"]
        )
        self.evidence = InsightReportEvidence(json: object["preprocess"]?.objectValue?["evidence"])
    }
}

struct InsightReportEvidence: Equatable {
    let asOf: String
    let periodStart: String?
    let periodEnd: String?
    let readingCount: Int
    let confidence: String

    init?(json: JSONValue?) {
        guard let object = json?.objectValue,
              let asOf = object["asOf"]?.stringValue,
              let readingCount = object["readingCount"]?.numberValue,
              let confidence = object["confidence"]?.stringValue else { return nil }

        self.asOf = asOf
        self.periodStart = object["periodStart"]?.stringValue
        self.periodEnd = object["periodEnd"]?.stringValue
        self.readingCount = Int(readingCount)
        self.confidence = confidence
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
    let evidence: InsightReportEvidence?

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
        self.evidence = InsightReportEvidence(json: object["preprocess"]?.objectValue?["evidence"])
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
    let factorColor: FactorColor?
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
        self.factorColor = object["factor_color"]?.stringValue.flatMap(FactorColor.init(rawValue:))
        self.text = object["text"]?.stringValue
    }

    var color: Color {
        factorColor?.color ?? marker?.color ?? .secondary
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

    var insightTrendUnit: String {
        switch self {
        case "body_fat_pct": "%"
        case "visceral_fat": ""
        default: "kg"
        }
    }
}

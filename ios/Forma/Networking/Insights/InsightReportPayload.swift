//
//  InsightReportPayload.swift
//  Forma
//
//  Created by Codex on 01/07/26.
//

import Foundation

struct InsightReportPayload: Equatable {
    let overview: InsightReportSection?
    let foundation: InsightReportSection?
    let momentum: InsightReportSection?
    let progress: InsightReportProgressSection?
    let lever: InsightReportSection?
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
    let bodyType: String?

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else {
            return nil
        }

        self.title = object["title"]?.stringValue
        self.headline = object["headline"]?.stringValue
        self.comment = object["comment"]?.stringValue
        self.bodyType = object["body_type"]?.stringValue
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
    let marker: String?
    let text: String?

    init?(json: JSONValue?) {
        guard let object = json?.objectValue else {
            return nil
        }

        self.marker = object["marker"]?.stringValue
        self.text = object["text"]?.stringValue
    }
}

struct InsightReportMetricSection: Equatable {
    let heading: String?
    let title: String?
    let headline: String?
    let comment: String?
    let remark: InsightReportRemark?
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
        case "body_fat_pct":
            return "Body Fat"
        case "fat_mass_kg", "fatMassKg", "fatMass30Days":
            return "Fat Mass"
        case "leanMass30Days":
            return "Lean Mass"
        case "muscle_mass_kg", "muscleRatio":
            return "Muscle Mass"
        case "visceralFatMassKg", "visceralFatPercent":
            return "Visceral Fat"
        case "subcutaneousFatMassKg", "subcutaneousFatPercent":
            return "Subcutaneous Fat"
        case "boneMassKg":
            return "Bone Mass"
        case "skeletalMuscleMassKg", "skeletalMuscleRatio":
            return "Skeletal Muscle"
        default:
            return displayRemarkMarker
        }
    }
}

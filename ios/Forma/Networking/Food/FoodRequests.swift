import Foundation

enum FoodMeal: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct FoodNutrition: Codable, Equatable, Identifiable {
    var id: String { "\(name)|\(servingDescription)" }
    let name: String
    let servingDescription: String
    var servings: Double
    var meal: FoodMeal
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double
    let saturatedFatG: Double
    let transFatG: Double
    let monounsaturatedFatG: Double
    let polyunsaturatedFatG: Double
    let sugarG: Double
    let addedSugarG: Double
    let sodiumMg: Double
    let cholesterolMg: Double
}

struct FoodChatMessage: Encodable, Identifiable, Equatable {
    let id: UUID
    let role: String
    let content: String

    init(id: UUID = UUID(), role: String, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }

    private enum CodingKeys: String, CodingKey { case role, content }
}

private struct FoodAnalysisBody: Encodable {
    let profileId: UUID
    let messages: [FoodChatMessage]
}

struct AnalyzeFoodRequest: APIRequest {
    typealias Response = FoodAnalysisResponse
    let path = "client/food/analyze"
    let method: HTTPMethod = .post
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem] = []
    let body: (any Encodable)?
    let requiresAuth = true

    init(profileId: UUID, messages: [FoodChatMessage]) {
        body = FoodAnalysisBody(profileId: profileId, messages: messages)
    }
}

struct FoodAnalysisResponse: Decodable {
    let ok: Bool
    let action: String
    let message: String
    let food: FoodNutrition?
}

private struct ConfirmFoodBody: Encodable {
    let profileId: UUID
    let food: FoodNutrition
}

struct ConfirmFoodRequest: APIRequest {
    typealias Response = ConfirmFoodResponse
    let path = "client/food/confirm"
    let method: HTTPMethod = .post
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem] = []
    let body: (any Encodable)?
    let requiresAuth = true

    init(profileId: UUID, food: FoodNutrition) {
        body = ConfirmFoodBody(profileId: profileId, food: food)
    }
}

struct ConfirmFoodResponse: Decodable { let ok: Bool }

struct GetSavedFoodsRequest: APIRequest {
    typealias Response = SavedFoodsResponse
    let path: String
    let method: HTTPMethod = .get
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem] = []
    let body: (any Encodable)? = nil
    let requiresAuth = true
    init(profileId: UUID) { path = "client/food/saved/\(profileId.uuidString.lowercased())" }
}

struct SavedFoodsResponse: Decodable { let ok: Bool; let foods: [FoodNutrition] }

struct GetFoodDashboardRequest: APIRequest {
    typealias Response = FoodDashboardResponse
    let path: String
    let method: HTTPMethod = .get
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem] = []
    let body: (any Encodable)? = nil
    let requiresAuth = true
    init(profileId: UUID) { path = "client/food/dashboard/\(profileId.uuidString.lowercased())" }
}

struct FoodDashboardResponse: Decodable {
    let ok: Bool
    let entries: [FoodEntry]
    let trends: [FoodTrend]
    let goals: FoodGoals
}

struct FoodEntry: Decodable, Identifiable {
    let id: UUID
    let name: String
    let servingDescription: String
    let servings: Double
    let meal: FoodMeal
    let loggedAt: String
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double
}

struct FoodTrend: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double

    var dateValue: Date { Self.dayFormatter.date(from: date) ?? .distantPast }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct FoodGoals: Decodable {
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
}

/// Ranked fuzzy matching for the local food library. This deliberately combines
/// token-prefix matching with Dice bigram similarity, so word order and small
/// typos do not force a network or AI request.
enum FoodSearch {
    static func matches(_ query: String, in foods: [FoodNutrition], limit: Int = 5) -> [FoodNutrition] {
        let needle = normalize(query)
        guard !needle.isEmpty else { return [] }
        let queryTokens = needle.split(separator: " ")
        let needlePairs = pairCounts(needle)
        let needlePairCount = needlePairs.values.reduce(0, +)
        return foods.compactMap { food -> (FoodNutrition, Double)? in
            let name = normalize(food.name)
            let haystack = "\(name) \(normalize(food.servingDescription))"
            var score = diceCoefficient(needle, haystack, lhsPairs: needlePairs, lhsPairCount: needlePairCount)
            if name == needle { score += 2 }
            if name.contains(needle) { score += 1 }
            let foodTokens = haystack.split(separator: " ")
            let hits = queryTokens.filter { queryToken in
                foodTokens.contains { $0.hasPrefix(queryToken) || queryToken.hasPrefix($0) }
            }.count
            score += Double(hits) / Double(max(queryTokens.count, 1))
            return score >= 0.34 ? (food, score) : nil
        }
        .sorted { lhs, rhs in
            lhs.1 == rhs.1
                ? lhs.0.name.localizedCaseInsensitiveCompare(rhs.0.name) == .orderedAscending
                : lhs.1 > rhs.1
        }
        .prefix(limit)
        .map(\.0)
    }

    private static func normalize(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: " ")
    }

    private static func diceCoefficient(
        _ lhs: String, _ rhs: String, lhsPairs: [String: Int], lhsPairCount: Int
    ) -> Double {
        guard lhs.count > 1, rhs.count > 1 else { return rhs.contains(lhs) ? 1 : 0 }
        let rhsPairs = pairCounts(rhs)
        let overlap = lhsPairs.reduce(into: 0) { result, item in
            result += min(item.value, rhsPairs[item.key, default: 0])
        }
        let count = lhsPairCount + rhsPairs.values.reduce(0, +)
        return count == 0 ? 0 : Double(2 * overlap) / Double(count)
    }

    private static func pairCounts(_ value: String) -> [String: Int] {
        let characters = Array(value)
        guard characters.count > 1 else { return [:] }
        return (0..<(characters.count - 1)).reduce(into: [:]) { result, index in
            result[String(characters[index...index + 1]), default: 0] += 1
        }
    }
}

import Foundation
import CoreData

// MARK: - Insights Service Protocol

protocol InsightsServiceProtocol {
    func generateDailyInsights(for entry: DailyEntry) async throws -> DailyInsight
    func generateTrendInsights(from entries: [DailyEntry], days: Int) async throws -> TrendInsight
}

// MARK: - Insight Models

struct DailyInsight: Codable, Identifiable {
    let id: UUID
    let date: Date
    let summary: String
    let highlights: [String]
    let concerns: [String]
    let suggestions: [AtomicHabit]
    let overallScore: Int // 1-10

    init(id: UUID = UUID(), date: Date = Date(), summary: String, highlights: [String], concerns: [String], suggestions: [AtomicHabit], overallScore: Int) {
        self.id = id
        self.date = date
        self.summary = summary
        self.highlights = highlights
        self.concerns = concerns
        self.suggestions = suggestions
        self.overallScore = overallScore
    }
}

struct TrendInsight: Codable, Identifiable {
    let id: UUID
    let generatedAt: Date
    let periodDays: Int
    let summary: String
    let patterns: [Pattern]
    let improvements: [String]
    let areasOfConcern: [String]
    let recommendations: [AtomicHabit]

    init(id: UUID = UUID(), generatedAt: Date = Date(), periodDays: Int, summary: String, patterns: [Pattern], improvements: [String], areasOfConcern: [String], recommendations: [AtomicHabit]) {
        self.id = id
        self.generatedAt = generatedAt
        self.periodDays = periodDays
        self.summary = summary
        self.patterns = patterns
        self.improvements = improvements
        self.areasOfConcern = areasOfConcern
        self.recommendations = recommendations
    }
}

struct Pattern: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: PatternCategory

    init(id: UUID = UUID(), title: String, description: String, category: PatternCategory) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
    }
}

enum PatternCategory: String, Codable {
    case sleep
    case anxiety
    case medication
    case activity
    case nutrition
    case focus
    case general
}

struct AtomicHabit: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: PatternCategory
    let difficulty: HabitDifficulty

    init(id: UUID = UUID(), title: String, description: String, category: PatternCategory, difficulty: HabitDifficulty = .easy) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
    }
}

enum HabitDifficulty: String, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case challenging = "Challenging"

    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "yellow"
        case .challenging: return "orange"
        }
    }
}

// MARK: - LLM Insights Service

class LLMInsightsService: InsightsServiceProtocol {
    private let apiKey: String?
    private let baseURL: String

    init(apiKey: String? = nil, baseURL: String = "https://api.anthropic.com/v1") {
        self.apiKey = apiKey ?? UserDefaults.standard.string(forKey: "anthropicAPIKey")
        self.baseURL = baseURL
    }

    var isConfigured: Bool {
        apiKey != nil && !apiKey!.isEmpty
    }

    func generateDailyInsights(for entry: DailyEntry) async throws -> DailyInsight {
        guard isConfigured else {
            return generateLocalDailyInsights(for: entry)
        }

        let prompt = buildDailyInsightsPrompt(for: entry)

        do {
            let response = try await callLLMAPI(prompt: prompt)
            return try parseDailyInsightsResponse(response)
        } catch {
            // Fallback to local insights on API error
            return generateLocalDailyInsights(for: entry)
        }
    }

    func generateTrendInsights(from entries: [DailyEntry], days: Int) async throws -> TrendInsight {
        guard isConfigured else {
            return generateLocalTrendInsights(from: entries, days: days)
        }

        let prompt = buildTrendInsightsPrompt(from: entries, days: days)

        do {
            let response = try await callLLMAPI(prompt: prompt)
            return try parseTrendInsightsResponse(response, days: days)
        } catch {
            // Fallback to local insights on API error
            return generateLocalTrendInsights(from: entries, days: days)
        }
    }

    // MARK: - API Call

    private func callLLMAPI(prompt: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw InsightsError.notConfigured
        }

        var request = URLRequest(url: URL(string: "\(baseURL)/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "system": """
            You are a supportive wellness assistant analyzing health tracking data.
            Provide objective, non-judgmental insights. Focus on patterns and small,
            actionable suggestions (atomic habits). Be encouraging but honest.
            Never diagnose medical conditions. Suggest consulting healthcare providers
            for concerning patterns. Respond in JSON format as specified.
            """
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw InsightsError.apiError
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = (json?["content"] as? [[String: Any]])?.first?["text"] as? String

        return content ?? ""
    }

    // MARK: - Prompt Building

    private func buildDailyInsightsPrompt(for entry: DailyEntry) -> String {
        """
        Analyze this wellness data and provide insights in JSON format:

        Date: \(entry.formattedDate)

        Sleep:
        - Hours: \(entry.hoursSlept)
        - Quality: \(entry.sleepQuality)/5
        - Racing thoughts: \(entry.racingThoughts ? "Yes" : "No")
        - Unusual dreams: \(entry.weirdDreams ? "Yes" : "No")

        Anxiety (0-10 scale):
        - Morning: \(entry.morningAnxiety)
        - Afternoon: \(entry.afternoonAnxiety)
        - Evening: \(entry.eveningAnxiety)
        - Triggers: \(entry.stressTriggers ?? "None noted")
        - Physical symptoms: \(entry.physicalSymptoms ?? "None noted")

        Focus:
        - Brain fog: \(entry.brainFog)/5
        - Forgetfulness: \(entry.forgetfulness)/5
        - Examples: \(entry.forgetfulnessExamples ?? "None noted")

        Activity:
        - Physically active: \(entry.physicallyActive ? "Yes" : "No")
        - Type: \(entry.activityType ?? "N/A")
        - Duration: \(entry.activityDuration ?? "N/A")

        Nutrition:
        - Meals: \(entry.mealsCount)
        - Food quality: \(entry.foodQuality ?? "Not rated")

        Mood: \(entry.overallMood ?? "Not noted")
        Notes: \(entry.otherNotes ?? "None")

        Respond with this JSON structure:
        {
            "summary": "Brief 1-2 sentence summary of the day",
            "highlights": ["Positive observation 1", "Positive observation 2"],
            "concerns": ["Area of concern if any"],
            "suggestions": [
                {
                    "title": "Small habit suggestion",
                    "description": "Why and how to implement",
                    "category": "sleep|anxiety|medication|activity|nutrition|focus|general",
                    "difficulty": "easy|medium|challenging"
                }
            ],
            "overallScore": 7
        }
        """
    }

    private func buildTrendInsightsPrompt(from entries: [DailyEntry], days: Int) -> String {
        let entrySummaries = entries.prefix(days).map { entry in
            """
            \(entry.formattedDate): Sleep \(entry.hoursSlept)h (Q:\(entry.sleepQuality)), \
            Anxiety avg \(String(format: "%.1f", entry.averageAnxiety)), \
            Brain fog \(entry.brainFog)/5, \
            Active: \(entry.physicallyActive ? "Yes" : "No")
            """
        }.joined(separator: "\n")

        return """
        Analyze these \(days)-day wellness trends and provide insights in JSON format:

        \(entrySummaries)

        Respond with this JSON structure:
        {
            "summary": "Overview of the period's wellness trends",
            "patterns": [
                {
                    "title": "Pattern name",
                    "description": "Description of the observed pattern",
                    "category": "sleep|anxiety|medication|activity|nutrition|focus|general"
                }
            ],
            "improvements": ["Area that has improved"],
            "areasOfConcern": ["Area that needs attention"],
            "recommendations": [
                {
                    "title": "Atomic habit recommendation",
                    "description": "Specific small action to take",
                    "category": "sleep|anxiety|medication|activity|nutrition|focus|general",
                    "difficulty": "easy|medium|challenging"
                }
            ]
        }
        """
    }

    // MARK: - Response Parsing

    private func parseDailyInsightsResponse(_ response: String) throws -> DailyInsight {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw InsightsError.parseError
        }

        let summary = json["summary"] as? String ?? "Unable to generate summary"
        let highlights = json["highlights"] as? [String] ?? []
        let concerns = json["concerns"] as? [String] ?? []
        let overallScore = json["overallScore"] as? Int ?? 5

        var suggestions: [AtomicHabit] = []
        if let suggestionsArray = json["suggestions"] as? [[String: Any]] {
            for suggestion in suggestionsArray {
                let habit = AtomicHabit(
                    title: suggestion["title"] as? String ?? "",
                    description: suggestion["description"] as? String ?? "",
                    category: PatternCategory(rawValue: suggestion["category"] as? String ?? "general") ?? .general,
                    difficulty: HabitDifficulty(rawValue: suggestion["difficulty"] as? String ?? "easy") ?? .easy
                )
                suggestions.append(habit)
            }
        }

        return DailyInsight(
            summary: summary,
            highlights: highlights,
            concerns: concerns,
            suggestions: suggestions,
            overallScore: overallScore
        )
    }

    private func parseTrendInsightsResponse(_ response: String, days: Int) throws -> TrendInsight {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw InsightsError.parseError
        }

        let summary = json["summary"] as? String ?? "Unable to generate summary"
        let improvements = json["improvements"] as? [String] ?? []
        let areasOfConcern = json["areasOfConcern"] as? [String] ?? []

        var patterns: [Pattern] = []
        if let patternsArray = json["patterns"] as? [[String: Any]] {
            for pattern in patternsArray {
                patterns.append(Pattern(
                    title: pattern["title"] as? String ?? "",
                    description: pattern["description"] as? String ?? "",
                    category: PatternCategory(rawValue: pattern["category"] as? String ?? "general") ?? .general
                ))
            }
        }

        var recommendations: [AtomicHabit] = []
        if let recsArray = json["recommendations"] as? [[String: Any]] {
            for rec in recsArray {
                recommendations.append(AtomicHabit(
                    title: rec["title"] as? String ?? "",
                    description: rec["description"] as? String ?? "",
                    category: PatternCategory(rawValue: rec["category"] as? String ?? "general") ?? .general,
                    difficulty: HabitDifficulty(rawValue: rec["difficulty"] as? String ?? "easy") ?? .easy
                ))
            }
        }

        return TrendInsight(
            periodDays: days,
            summary: summary,
            patterns: patterns,
            improvements: improvements,
            areasOfConcern: areasOfConcern,
            recommendations: recommendations
        )
    }

    // MARK: - Local Fallback Insights

    private func generateLocalDailyInsights(for entry: DailyEntry) -> DailyInsight {
        var highlights: [String] = []
        var concerns: [String] = []
        var suggestions: [AtomicHabit] = []

        // Analyze sleep
        if entry.hoursSlept >= 7 {
            highlights.append("Good sleep duration (\(String(format: "%.1f", entry.hoursSlept)) hours)")
        } else if entry.hoursSlept < 6 {
            concerns.append("Sleep was below recommended 7-9 hours")
            suggestions.append(AtomicHabit(
                title: "Set a bedtime alarm",
                description: "Set an alarm 30 minutes before your target bedtime as a wind-down reminder",
                category: .sleep,
                difficulty: .easy
            ))
        }

        // Analyze anxiety
        let avgAnxiety = entry.averageAnxiety
        if avgAnxiety <= 3 {
            highlights.append("Low anxiety levels throughout the day")
        } else if avgAnxiety >= 6 {
            concerns.append("Elevated anxiety levels noted")
            suggestions.append(AtomicHabit(
                title: "2-minute breathing exercise",
                description: "Try box breathing (4-4-4-4) when you notice anxiety rising",
                category: .anxiety,
                difficulty: .easy
            ))
        }

        // Analyze activity
        if entry.physicallyActive {
            highlights.append("Stayed physically active")
        } else {
            suggestions.append(AtomicHabit(
                title: "5-minute walk",
                description: "A short walk can boost mood and energy. Start with just 5 minutes.",
                category: .activity,
                difficulty: .easy
            ))
        }

        // Analyze brain fog
        if entry.brainFog >= 3 {
            concerns.append("Significant brain fog reported")
            suggestions.append(AtomicHabit(
                title: "Hydration check",
                description: "Drink a glass of water and track if it helps with mental clarity",
                category: .focus,
                difficulty: .easy
            ))
        }

        // Calculate overall score
        var score = 5
        score += entry.hoursSlept >= 7 ? 1 : (entry.hoursSlept < 5 ? -1 : 0)
        score += avgAnxiety <= 3 ? 1 : (avgAnxiety >= 7 ? -1 : 0)
        score += entry.physicallyActive ? 1 : 0
        score += entry.brainFog <= 2 ? 1 : (entry.brainFog >= 4 ? -1 : 0)
        score = max(1, min(10, score))

        let summary = generateLocalSummary(entry: entry, score: score)

        return DailyInsight(
            summary: summary,
            highlights: highlights,
            concerns: concerns,
            suggestions: suggestions,
            overallScore: score
        )
    }

    private func generateLocalSummary(entry: DailyEntry, score: Int) -> String {
        let sleepDesc = entry.hoursSlept >= 7 ? "well-rested" : (entry.hoursSlept < 6 ? "sleep-deprived" : "moderately rested")
        let anxietyDesc = entry.averageAnxiety <= 3 ? "calm" : (entry.averageAnxiety >= 6 ? "anxious" : "manageable stress")

        return "A \(sleepDesc) day with \(anxietyDesc) levels. Overall wellness score: \(score)/10."
    }

    private func generateLocalTrendInsights(from entries: [DailyEntry], days: Int) -> TrendInsight {
        let recentEntries = Array(entries.prefix(days))
        guard !recentEntries.isEmpty else {
            return TrendInsight(
                periodDays: days,
                summary: "Not enough data to analyze trends yet.",
                patterns: [],
                improvements: [],
                areasOfConcern: [],
                recommendations: []
            )
        }

        var patterns: [Pattern] = []
        var improvements: [String] = []
        var concerns: [String] = []
        var recommendations: [AtomicHabit] = []

        // Analyze sleep trend
        let avgSleep = recentEntries.map { $0.hoursSlept }.reduce(0, +) / Double(recentEntries.count)
        if avgSleep < 7 {
            patterns.append(Pattern(
                title: "Below-target sleep",
                description: "Average of \(String(format: "%.1f", avgSleep)) hours over \(days) days",
                category: .sleep
            ))
            concerns.append("Sleep duration averaging below recommended levels")
        }

        // Analyze anxiety trend
        let avgAnxiety = recentEntries.map { $0.averageAnxiety }.reduce(0, +) / Double(recentEntries.count)
        if avgAnxiety > 5 {
            patterns.append(Pattern(
                title: "Elevated anxiety pattern",
                description: "Average anxiety of \(String(format: "%.1f", avgAnxiety))/10",
                category: .anxiety
            ))
            concerns.append("Consistent elevated anxiety levels")
            recommendations.append(AtomicHabit(
                title: "Morning mindfulness",
                description: "Start with 2 minutes of morning meditation to set a calmer tone for the day",
                category: .anxiety,
                difficulty: .easy
            ))
        }

        // Activity pattern
        let activeDays = recentEntries.filter { $0.physicallyActive }.count
        let activityRate = Double(activeDays) / Double(recentEntries.count)
        if activityRate >= 0.5 {
            improvements.append("Maintaining regular physical activity (\(activeDays) of \(recentEntries.count) days)")
        } else {
            patterns.append(Pattern(
                title: "Low activity levels",
                description: "Active only \(activeDays) of \(recentEntries.count) days",
                category: .activity
            ))
        }

        let summary = """
        Over the past \(days) days: Average sleep \(String(format: "%.1f", avgSleep))h, \
        average anxiety \(String(format: "%.1f", avgAnxiety))/10, \
        active \(activeDays)/\(recentEntries.count) days.
        """

        return TrendInsight(
            periodDays: days,
            summary: summary,
            patterns: patterns,
            improvements: improvements,
            areasOfConcern: concerns,
            recommendations: recommendations
        )
    }
}

// MARK: - Errors

enum InsightsError: Error {
    case notConfigured
    case apiError
    case parseError
}

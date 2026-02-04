import SwiftUI
import CoreData

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        fetchRequest: DailyEntry.recentEntriesFetchRequest(limit: 30),
        animation: .default
    )
    private var entries: FetchedResults<DailyEntry>

    @State private var selectedTab = 0
    @State private var dailyInsight: DailyInsight?
    @State private var trendInsight: TrendInsight?
    @State private var isLoadingDaily = false
    @State private var isLoadingTrend = false
    @State private var showingSettings = false
    @State private var trendPeriod = 7

    private let insightsService = LLMInsightsService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Tab selector
                    Picker("Insight Type", selection: $selectedTab) {
                        Text("Today").tag(0)
                        Text("Trends").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        dailyInsightsSection
                    } else {
                        trendInsightsSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                InsightsSettingsView()
            }
            .onAppear {
                if dailyInsight == nil, let todayEntry = entries.first {
                    loadDailyInsights(for: todayEntry)
                }
            }
        }
    }

    // MARK: - Daily Insights

    private var dailyInsightsSection: some View {
        VStack(spacing: 16) {
            if entries.isEmpty {
                noDataView
            } else if isLoadingDaily {
                loadingView
            } else if let insight = dailyInsight {
                dailyInsightContent(insight)
            } else {
                generateInsightsButton(isDaily: true)
            }
        }
        .padding(.horizontal)
    }

    private func dailyInsightContent(_ insight: DailyInsight) -> some View {
        VStack(spacing: 16) {
            // Score card
            ScoreCard(score: insight.overallScore)

            // Summary
            InsightCard(title: "Summary", icon: "text.quote") {
                Text(insight.summary)
                    .font(.body)
            }

            // Highlights
            if !insight.highlights.isEmpty {
                InsightCard(title: "Highlights", icon: "star.fill", iconColor: .yellow) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(insight.highlights, id: \.self) { highlight in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(highlight)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }

            // Concerns
            if !insight.concerns.isEmpty {
                InsightCard(title: "Areas to Watch", icon: "exclamationmark.triangle.fill", iconColor: .orange) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(insight.concerns, id: \.self) { concern in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(concern)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }

            // Suggestions
            if !insight.suggestions.isEmpty {
                InsightCard(title: "Small Steps", icon: "lightbulb.fill", iconColor: .blue) {
                    VStack(spacing: 12) {
                        ForEach(insight.suggestions) { habit in
                            AtomicHabitRow(habit: habit)
                        }
                    }
                }
            }

            // Refresh button
            Button {
                if let todayEntry = entries.first {
                    loadDailyInsights(for: todayEntry)
                }
            } label: {
                Label("Refresh Insights", systemImage: "arrow.clockwise")
                    .font(.subheadline)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Trend Insights

    private var trendInsightsSection: some View {
        VStack(spacing: 16) {
            // Period selector
            HStack {
                Text("Analyze last")
                Picker("Period", selection: $trendPeriod) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            if entries.count < 3 {
                notEnoughDataView
            } else if isLoadingTrend {
                loadingView
            } else if let insight = trendInsight, insight.periodDays == trendPeriod {
                trendInsightContent(insight)
            } else {
                generateInsightsButton(isDaily: false)
            }
        }
        .padding(.horizontal)
        .onChange(of: trendPeriod) { _, _ in
            trendInsight = nil
        }
    }

    private func trendInsightContent(_ insight: TrendInsight) -> some View {
        VStack(spacing: 16) {
            // Summary
            InsightCard(title: "Overview", icon: "chart.line.uptrend.xyaxis") {
                Text(insight.summary)
                    .font(.body)
            }

            // Patterns
            if !insight.patterns.isEmpty {
                InsightCard(title: "Patterns Detected", icon: "waveform.path.ecg") {
                    VStack(spacing: 12) {
                        ForEach(insight.patterns) { pattern in
                            PatternRow(pattern: pattern)
                        }
                    }
                }
            }

            // Improvements
            if !insight.improvements.isEmpty {
                InsightCard(title: "Improvements", icon: "arrow.up.circle.fill", iconColor: .green) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(insight.improvements, id: \.self) { improvement in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(improvement)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }

            // Areas of concern
            if !insight.areasOfConcern.isEmpty {
                InsightCard(title: "Needs Attention", icon: "exclamationmark.triangle.fill", iconColor: .orange) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(insight.areasOfConcern, id: \.self) { concern in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(concern)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }

            // Recommendations
            if !insight.recommendations.isEmpty {
                InsightCard(title: "Recommended Habits", icon: "lightbulb.fill", iconColor: .blue) {
                    VStack(spacing: 12) {
                        ForEach(insight.recommendations) { habit in
                            AtomicHabitRow(habit: habit)
                        }
                    }
                }
            }

            // Refresh button
            Button {
                loadTrendInsights()
            } label: {
                Label("Refresh Analysis", systemImage: "arrow.clockwise")
                    .font(.subheadline)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Helper Views

    private var noDataView: some View {
        ContentUnavailableView {
            Label("No Data Yet", systemImage: "chart.bar.doc.horizontal")
        } description: {
            Text("Complete your first daily check-in to see insights.")
        }
    }

    private var notEnoughDataView: some View {
        ContentUnavailableView {
            Label("More Data Needed", systemImage: "chart.line.uptrend.xyaxis")
        } description: {
            Text("Log at least 3 days of data to see trend insights.")
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing your data...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func generateInsightsButton(isDaily: Bool) -> some View {
        Button {
            if isDaily, let todayEntry = entries.first {
                loadDailyInsights(for: todayEntry)
            } else {
                loadTrendInsights()
            }
        } label: {
            Label(
                isDaily ? "Generate Today's Insights" : "Analyze Trends",
                systemImage: "sparkles"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Data Loading

    private func loadDailyInsights(for entry: DailyEntry) {
        isLoadingDaily = true
        Task {
            do {
                let insight = try await insightsService.generateDailyInsights(for: entry)
                await MainActor.run {
                    dailyInsight = insight
                    isLoadingDaily = false
                }
            } catch {
                await MainActor.run {
                    isLoadingDaily = false
                }
            }
        }
    }

    private func loadTrendInsights() {
        isLoadingTrend = true
        Task {
            do {
                let insight = try await insightsService.generateTrendInsights(
                    from: Array(entries),
                    days: trendPeriod
                )
                await MainActor.run {
                    trendInsight = insight
                    isLoadingTrend = false
                }
            } catch {
                await MainActor.run {
                    isLoadingTrend = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ScoreCard: View {
    let score: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("Today's Wellness Score")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(score)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)

            Text("out of 10")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(scoreColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var scoreColor: Color {
        switch score {
        case 8...10: return .green
        case 6...7: return .yellow
        case 4...5: return .orange
        default: return .red
        }
    }
}

struct InsightCard<Content: View>: View {
    let title: String
    let icon: String
    var iconColor: Color = .accentColor
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AtomicHabitRow: View {
    let habit: AtomicHabit

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(habit.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(habit.difficulty.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(difficultyColor.opacity(0.2))
                    .foregroundStyle(difficultyColor)
                    .clipShape(Capsule())
            }

            Text(habit.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: categoryIcon)
                    .font(.caption2)
                Text(habit.category.rawValue.capitalized)
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var difficultyColor: Color {
        switch habit.difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .challenging: return .orange
        }
    }

    private var categoryIcon: String {
        switch habit.category {
        case .sleep: return "bed.double.fill"
        case .anxiety: return "heart.fill"
        case .medication: return "pills.fill"
        case .activity: return "figure.run"
        case .nutrition: return "fork.knife"
        case .focus: return "brain.head.profile"
        case .general: return "star.fill"
        }
    }
}

struct PatternRow: View {
    let pattern: Pattern

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundStyle(.accentColor)
                    .font(.caption)
                Text(pattern.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Text(pattern.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var categoryIcon: String {
        switch pattern.category {
        case .sleep: return "bed.double.fill"
        case .anxiety: return "heart.fill"
        case .medication: return "pills.fill"
        case .activity: return "figure.run"
        case .nutrition: return "fork.knife"
        case .focus: return "brain.head.profile"
        case .general: return "chart.xyaxis.line"
        }
    }
}

// MARK: - Settings View

struct InsightsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("anthropicAPIKey") private var apiKey = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("API Key", text: $apiKey)
                } header: {
                    Text("Anthropic API (Optional)")
                } footer: {
                    Text("Add your Anthropic API key to enable AI-powered insights. Without an API key, the app provides rule-based insights from your data.")
                }

                Section {
                    HStack {
                        Image(systemName: apiKey.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(apiKey.isEmpty ? .gray : .green)
                        Text(apiKey.isEmpty ? "Using local insights" : "AI insights enabled")
                    }
                } header: {
                    Text("Status")
                }
            }
            .navigationTitle("Insights Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    InsightsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

import SwiftUI
import Charts
import CoreData

struct ChartsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        fetchRequest: DailyEntry.recentEntriesFetchRequest(limit: 30),
        animation: .default
    )
    private var entries: FetchedResults<DailyEntry>

    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case twoWeeks = "14 Days"
        case month = "30 Days"

        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }

    var filteredEntries: [DailyEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return entries.filter { ($0.date ?? Date()) >= cutoffDate }
            .sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if filteredEntries.isEmpty {
                        emptyState
                    } else {
                        // Anxiety Chart
                        anxietyChart

                        // Sleep Chart
                        sleepChart

                        // Focus Chart
                        focusChart

                        // Summary Stats
                        summaryStats
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Trends")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Data Yet", systemImage: "chart.line.uptrend.xyaxis")
        } description: {
            Text("Add daily entries to see your wellness trends over time.")
        }
        .padding(.top, 60)
    }

    // MARK: - Anxiety Chart

    private var anxietyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Anxiety Levels")
                .font(.headline)
                .padding(.horizontal)

            Chart(filteredEntries) { entry in
                LineMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Morning", entry.morningAnxiety)
                )
                .foregroundStyle(by: .value("Time", "Morning"))
                .symbol(Circle())

                LineMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Afternoon", entry.afternoonAnxiety)
                )
                .foregroundStyle(by: .value("Time", "Afternoon"))
                .symbol(Circle())

                LineMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Evening", entry.eveningAnxiety)
                )
                .foregroundStyle(by: .value("Time", "Evening"))
                .symbol(Circle())
            }
            .chartYScale(domain: 0...10)
            .chartYAxis {
                AxisMarks(values: [0, 2, 4, 6, 8, 10])
            }
            .chartForegroundStyleScale([
                "Morning": Color.orange,
                "Afternoon": Color.blue,
                "Evening": Color.purple
            ])
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Sleep Chart

    private var sleepChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep")
                .font(.headline)
                .padding(.horizontal)

            Chart(filteredEntries) { entry in
                BarMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Hours", entry.hoursSlept)
                )
                .foregroundStyle(sleepColor(for: entry.hoursSlept))
            }
            .chartYScale(domain: 0...12)
            .chartYAxis {
                AxisMarks(values: [0, 4, 8, 12]) { value in
                    AxisValueLabel {
                        if let hours = value.as(Int.self) {
                            Text("\(hours)h")
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: 150)
            .padding(.horizontal)

            // Sleep quality line
            Chart(filteredEntries) { entry in
                LineMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Quality", entry.sleepQuality)
                )
                .foregroundStyle(.indigo)
                .symbol(Circle())
            }
            .chartYScale(domain: 1...5)
            .chartYAxis {
                AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                    AxisValueLabel {
                        if let quality = value.as(Int.self) {
                            Text("\(quality)")
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: 100)
            .padding(.horizontal)

            Text("Sleep Quality (1-5)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func sleepColor(for hours: Double) -> Color {
        switch hours {
        case 7...9: return .green
        case 6..<7, 9..<10: return .yellow
        default: return .red
        }
    }

    // MARK: - Focus Chart

    private var focusChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus & Functioning")
                .font(.headline)
                .padding(.horizontal)

            Chart(filteredEntries) { entry in
                LineMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Brain Fog", entry.brainFog)
                )
                .foregroundStyle(by: .value("Metric", "Brain Fog"))
                .symbol(Circle())

                LineMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Forgetfulness", entry.forgetfulness)
                )
                .foregroundStyle(by: .value("Metric", "Forgetfulness"))
                .symbol(Circle())
            }
            .chartYScale(domain: 0...5)
            .chartYAxis {
                AxisMarks(values: [0, 1, 2, 3, 4, 5])
            }
            .chartForegroundStyleScale([
                "Brain Fog": Color.teal,
                "Forgetfulness": Color.pink
            ])
            .frame(height: 150)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Period Summary")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Avg Anxiety",
                    value: String(format: "%.1f", averageAnxiety),
                    subtitle: "out of 10",
                    color: anxietyColor
                )

                StatCard(
                    title: "Avg Sleep",
                    value: String(format: "%.1f", averageSleep),
                    subtitle: "hours",
                    color: .indigo
                )

                StatCard(
                    title: "Active Days",
                    value: "\(activeDays)",
                    subtitle: "of \(filteredEntries.count)",
                    color: .green
                )

                StatCard(
                    title: "Meds Adherence",
                    value: "\(medicationAdherence)%",
                    subtitle: "Concerta",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var averageAnxiety: Double {
        guard !filteredEntries.isEmpty else { return 0 }
        let total = filteredEntries.reduce(0.0) { $0 + $1.averageAnxiety }
        return total / Double(filteredEntries.count)
    }

    private var anxietyColor: Color {
        switch averageAnxiety {
        case 0..<3: return .green
        case 3..<5: return .yellow
        case 5..<7: return .orange
        default: return .red
        }
    }

    private var averageSleep: Double {
        guard !filteredEntries.isEmpty else { return 0 }
        let total = filteredEntries.reduce(0.0) { $0 + $1.hoursSlept }
        return total / Double(filteredEntries.count)
    }

    private var activeDays: Int {
        filteredEntries.filter { $0.physicallyActive }.count
    }

    private var medicationAdherence: Int {
        guard !filteredEntries.isEmpty else { return 0 }
        let taken = filteredEntries.filter { $0.concertaTaken }.count
        return Int((Double(taken) / Double(filteredEntries.count)) * 100)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ChartsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

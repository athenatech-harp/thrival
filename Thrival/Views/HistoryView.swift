import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        fetchRequest: DailyEntry.recentEntriesFetchRequest(limit: 100),
        animation: .default
    )
    private var entries: FetchedResults<DailyEntry>

    @State private var searchText = ""
    @State private var selectedEntry: DailyEntry?

    var filteredEntries: [DailyEntry] {
        if searchText.isEmpty {
            return Array(entries)
        }
        return entries.filter { entry in
            entry.overallMood?.localizedCaseInsensitiveContains(searchText) == true ||
            entry.stressTriggers?.localizedCaseInsensitiveContains(searchText) == true ||
            entry.otherNotes?.localizedCaseInsensitiveContains(searchText) == true ||
            entry.formattedDate.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedEntries: [(String, [DailyEntry])] {
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            entry.date?.formatted(.dateTime.month(.wide).year()) ?? "Unknown"
        }
        return grouped.sorted { ($0.value.first?.date ?? .distantPast) > ($1.value.first?.date ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search entries")
            .sheet(item: $selectedEntry) { entry in
                EntryDetailView(entry: entry)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Entries Yet", systemImage: "calendar.badge.plus")
        } description: {
            Text("Start tracking your wellness by adding your first daily entry.")
        }
    }

    private var entryList: some View {
        List {
            ForEach(groupedEntries, id: \.0) { month, monthEntries in
                Section(month) {
                    ForEach(monthEntries) { entry in
                        EntryRow(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEntry = entry
                            }
                    }
                    .onDelete { indexSet in
                        deleteEntries(at: indexSet, from: monthEntries)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func deleteEntries(at offsets: IndexSet, from monthEntries: [DailyEntry]) {
        for index in offsets {
            let entry = monthEntries[index]
            viewContext.delete(entry)
        }

        do {
            try viewContext.save()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
}

struct EntryRow: View {
    let entry: DailyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Date header
            HStack {
                Text(entry.formattedDayOfWeek)
                    .font(.headline)
                Text(entry.formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // Stats with clear labels
            HStack(spacing: 12) {
                StatBadge(
                    icon: "heart.fill",
                    label: "Anxiety",
                    value: String(format: "%.1f", entry.averageAnxiety),
                    color: anxietyColor
                )

                StatBadge(
                    icon: "bed.double.fill",
                    label: "Sleep",
                    value: String(format: "%.1fh", entry.hoursSlept),
                    color: sleepColor
                )

                StatBadge(
                    icon: "brain.head.profile",
                    label: "Focus",
                    value: "\(5 - Int(entry.brainFog))/5",
                    color: focusColor
                )

                StatBadge(
                    icon: "pills.fill",
                    label: "Meds",
                    value: medicationStatus,
                    color: medicationColor
                )

                Spacer()
            }

            // Mood note if available
            if let mood = entry.overallMood, !mood.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "quote.opening")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(mood)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var anxietyColor: Color {
        let avg = entry.averageAnxiety
        switch avg {
        case 0..<3: return .green
        case 3..<5: return .yellow
        case 5..<7: return .orange
        default: return .red
        }
    }

    private var sleepColor: Color {
        let hours = entry.hoursSlept
        switch hours {
        case 7...: return .green
        case 6..<7: return .yellow
        case 5..<6: return .orange
        default: return .red
        }
    }

    private var focusColor: Color {
        let fog = entry.brainFog
        switch fog {
        case 0...1: return .green
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    private var medicationStatus: String {
        if let logs = entry.medicationLogs as? Set<MedicationLog> {
            let taken = logs.filter { $0.taken }.count
            let total = logs.count
            if total == 0 { return "—" }
            return "\(taken)/\(total)"
        }
        return "—"
    }

    private var medicationColor: Color {
        if let logs = entry.medicationLogs as? Set<MedicationLog> {
            let taken = logs.filter { $0.taken }.count
            let applicable = logs.filter { !$0.notApplicable }.count
            if applicable == 0 { return .gray }
            if taken == applicable { return .green }
            if taken > 0 { return .yellow }
            return .red
        }
        return .gray
    }
}

struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.formattedDayOfWeek)
                    .font(.headline)
                Text(entry.formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 16) {
                // Anxiety indicator
                anxietyIndicator

                // Sleep indicator
                sleepIndicator

                // Medications indicator
                medicationsIndicator

                Spacer()
            }
            .font(.caption)

            if let mood = entry.overallMood, !mood.isEmpty {
                Text(mood)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var anxietyIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .foregroundStyle(anxietyColor)
            Text("Avg: \(String(format: "%.1f", entry.averageAnxiety))")
                .foregroundStyle(.secondary)
        }
    }

    private var sleepIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "bed.double.fill")
                .foregroundStyle(.indigo)
            Text("\(String(format: "%.1f", entry.hoursSlept))h")
                .foregroundStyle(.secondary)
        }
    }

    private var medicationsIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "pills.fill")
                .foregroundStyle(medicationsTaken ? .green : .gray)
            Text(medicationsTaken ? "Meds" : "No meds")
                .foregroundStyle(.secondary)
        }
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

    private var medicationsTaken: Bool {
        entry.concertaTaken || entry.nortryptilineTaken
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

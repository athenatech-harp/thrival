import SwiftUI

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: DailyEntry

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Header
                    VStack(spacing: 4) {
                        Text(entry.formattedDayOfWeek)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(entry.formattedDate)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Medications
                    DetailSection(title: "Medications", icon: "pills.fill") {
                        DetailRow(label: "Concerta", value: entry.concertaTaken ? "\(Int(entry.concertaDose))mg at \(entry.concertaTime?.formatted(date: .omitted, time: .shortened) ?? "—")" : "Not taken")
                        DetailRow(label: "Estradiol", value: entry.estradiolApplied ? (entry.estradiolDosage ?? "Applied") : "Not applied")
                        DetailRow(label: "Nortryptiline", value: entry.nortryptilineTaken ? "\(Int(entry.nortryptilineDose))mg" : "Not taken")
                    }

                    // Sleep
                    DetailSection(title: "Sleep", icon: "bed.double.fill") {
                        DetailRow(label: "Hours slept", value: String(format: "%.1f hours", entry.hoursSlept))
                        DetailRow(label: "Quality", value: entry.sleepQualityDescription)
                        DetailRow(label: "Racing thoughts", value: entry.racingThoughts ? "Yes" : "No")
                        DetailRow(label: "Weird dreams", value: entry.weirdDreams ? "Yes" : "No")
                    }

                    // Anxiety
                    DetailSection(title: "Stress & Anxiety", icon: "heart.text.square.fill") {
                        DetailRow(label: "Morning", value: "\(entry.morningAnxiety)/10")
                        DetailRow(label: "Afternoon", value: "\(entry.afternoonAnxiety)/10")
                        DetailRow(label: "Evening", value: "\(entry.eveningAnxiety)/10")
                        DetailRow(label: "Average", value: String(format: "%.1f/10", entry.averageAnxiety))

                        if let triggers = entry.stressTriggers, !triggers.isEmpty {
                            DetailTextRow(label: "Triggers", value: triggers)
                        }
                        if let symptoms = entry.physicalSymptoms, !symptoms.isEmpty {
                            DetailTextRow(label: "Physical symptoms", value: symptoms)
                        }
                    }

                    // Focus
                    DetailSection(title: "Focus & Functioning", icon: "brain.head.profile") {
                        DetailRow(label: "Brain fog", value: "\(entry.brainFog)/5 (\(entry.brainFogDescription))")
                        DetailRow(label: "Forgetfulness", value: "\(entry.forgetfulness)/5 (\(entry.forgetfulnessDescription))")

                        if let examples = entry.forgetfulnessExamples, !examples.isEmpty {
                            DetailTextRow(label: "Examples", value: examples)
                        }
                    }

                    // Fitness
                    DetailSection(title: "Fitness & Activity", icon: "figure.run") {
                        DetailRow(label: "Active", value: entry.physicallyActive ? "Yes" : "No")
                        if entry.physicallyActive {
                            if let type = entry.activityType, !type.isEmpty {
                                DetailRow(label: "Activity", value: type)
                            }
                            if let duration = entry.activityDuration, !duration.isEmpty {
                                DetailRow(label: "Duration", value: duration)
                            }
                        }
                    }

                    // Nutrition
                    DetailSection(title: "Nutrition", icon: "fork.knife") {
                        DetailRow(label: "Meals", value: "\(entry.mealsCount)")
                        DetailRow(label: "Food quality", value: entry.foodQuality ?? "—")
                    }

                    // General
                    if let mood = entry.overallMood, !mood.isEmpty,
                       let notes = entry.otherNotes, !notes.isEmpty {
                        DetailSection(title: "General", icon: "note.text") {
                            if !mood.isEmpty {
                                DetailTextRow(label: "Mood", value: mood)
                            }
                            if !notes.isEmpty {
                                DetailTextRow(label: "Notes", value: notes)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Entry Details")
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

struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.headline)
            }

            VStack(spacing: 8) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct DetailTextRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let entry = DailyEntry(context: context)
    entry.id = UUID()
    entry.date = Date()
    entry.concertaTaken = true
    entry.concertaDose = 36
    entry.concertaTime = Date()
    entry.hoursSlept = 7.5
    entry.sleepQuality = 4
    entry.morningAnxiety = 3
    entry.afternoonAnxiety = 5
    entry.eveningAnxiety = 2
    entry.stressTriggers = "Work deadlines, traffic"
    entry.brainFog = 2
    entry.forgetfulness = 1
    entry.physicallyActive = true
    entry.activityType = "Walking"
    entry.activityDuration = "30 minutes"
    entry.mealsCount = 3
    entry.foodQuality = "Good"
    entry.overallMood = "Productive but tired"

    return EntryDetailView(entry: entry)
}

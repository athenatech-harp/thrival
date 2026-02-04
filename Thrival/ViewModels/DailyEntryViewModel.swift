import Foundation
import CoreData
import SwiftUI

@MainActor
class DailyEntryViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private var existingEntry: DailyEntry?

    // Entry metadata
    @Published var date: Date = Date()
    @Published var isEditing: Bool = false

    // Dynamic Medications
    @Published var medications: [Medication] = []
    @Published var medicationLogs: [UUID: MedicationLogState] = [:]

    // Sleep
    @Published var hoursSlept: Double = 7.0
    @Published var sleepQuality: Int = 3
    @Published var racingThoughts: Bool = false
    @Published var weirdDreams: Bool = false

    // Stress & Anxiety
    @Published var stressTriggers: String = ""
    @Published var morningAnxiety: Int = 0
    @Published var afternoonAnxiety: Int = 0
    @Published var eveningAnxiety: Int = 0
    @Published var physicalSymptoms: String = ""

    // Focus & Functioning
    @Published var brainFog: Int = 0
    @Published var forgetfulness: Int = 0
    @Published var forgetfulnessExamples: String = ""

    // Fitness & Activity
    @Published var physicallyActive: Bool = false
    @Published var activityType: String = ""
    @Published var activityDuration: String = ""

    // Nutrition
    @Published var mealsCount: Int = 3
    @Published var foodQuality: FoodQuality = .ok

    // General
    @Published var overallMood: String = ""
    @Published var otherNotes: String = ""

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadMedications()
        loadTodayEntry()
    }

    var dayOfWeek: String {
        date.formatted(.dateTime.weekday(.wide))
    }

    var formattedDate: String {
        date.formatted(date: .long, time: .omitted)
    }

    var hasMedications: Bool {
        !medications.isEmpty
    }

    func loadMedications() {
        let request = Medication.fetchRequest(activeOnly: true)
        medications = (try? viewContext.fetch(request)) ?? []

        // Initialize log states for each medication
        for medication in medications {
            if medicationLogs[medication.id!] == nil {
                medicationLogs[medication.id!] = MedicationLogState(
                    status: .pending,
                    dosage: medication.formattedDosage,
                    timeTaken: nil,
                    notes: ""
                )
            }
        }
    }

    func loadTodayEntry() {
        let request = DailyEntry.fetchRequest(for: date)
        if let entry = try? viewContext.fetch(request).first {
            existingEntry = entry
            isEditing = true
            loadFromEntry(entry)
        }
    }

    func loadEntry(for selectedDate: Date) {
        date = selectedDate
        let request = DailyEntry.fetchRequest(for: selectedDate)
        if let entry = try? viewContext.fetch(request).first {
            existingEntry = entry
            isEditing = true
            loadFromEntry(entry)
        } else {
            existingEntry = nil
            isEditing = false
            resetToDefaults()
        }
    }

    private func loadFromEntry(_ entry: DailyEntry) {
        // Load medication logs
        if let logs = entry.medicationLogs as? Set<MedicationLog> {
            for log in logs {
                guard let medId = log.medication?.id else { continue }
                medicationLogs[medId] = MedicationLogState(
                    status: log.status,
                    dosage: log.dosage ?? "",
                    timeTaken: log.timeTaken,
                    notes: log.notes ?? ""
                )
            }
        }

        hoursSlept = entry.hoursSlept
        sleepQuality = Int(entry.sleepQuality)
        racingThoughts = entry.racingThoughts
        weirdDreams = entry.weirdDreams

        stressTriggers = entry.stressTriggers ?? ""
        morningAnxiety = Int(entry.morningAnxiety)
        afternoonAnxiety = Int(entry.afternoonAnxiety)
        eveningAnxiety = Int(entry.eveningAnxiety)
        physicalSymptoms = entry.physicalSymptoms ?? ""

        brainFog = Int(entry.brainFog)
        forgetfulness = Int(entry.forgetfulness)
        forgetfulnessExamples = entry.forgetfulnessExamples ?? ""

        physicallyActive = entry.physicallyActive
        activityType = entry.activityType ?? ""
        activityDuration = entry.activityDuration ?? ""

        mealsCount = Int(entry.mealsCount)
        foodQuality = FoodQuality(rawValue: entry.foodQuality ?? "OK") ?? .ok

        overallMood = entry.overallMood ?? ""
        otherNotes = entry.otherNotes ?? ""
    }

    private func resetToDefaults() {
        // Reset medication logs to pending with default dosages
        for medication in medications {
            medicationLogs[medication.id!] = MedicationLogState(
                status: .pending,
                dosage: medication.formattedDosage,
                timeTaken: nil,
                notes: ""
            )
        }

        hoursSlept = 7.0
        sleepQuality = 3
        racingThoughts = false
        weirdDreams = false

        stressTriggers = ""
        morningAnxiety = 0
        afternoonAnxiety = 0
        eveningAnxiety = 0
        physicalSymptoms = ""

        brainFog = 0
        forgetfulness = 0
        forgetfulnessExamples = ""

        physicallyActive = false
        activityType = ""
        activityDuration = ""

        mealsCount = 3
        foodQuality = .ok

        overallMood = ""
        otherNotes = ""
    }

    func save() {
        let entry = existingEntry ?? DailyEntry(context: viewContext)

        if existingEntry == nil {
            entry.id = UUID()
        }

        entry.date = Calendar.current.startOfDay(for: date)
        entry.dayOfWeek = dayOfWeek

        // Save medication logs
        for medication in medications {
            guard let medId = medication.id,
                  let logState = medicationLogs[medId] else { continue }

            let log = MedicationLog.findOrCreate(
                in: viewContext,
                medication: medication,
                dailyEntry: entry
            )

            log.status = logState.status
            log.dosage = logState.dosage
            log.timeTaken = logState.timeTaken
            log.notes = logState.notes
        }

        // Sleep
        entry.hoursSlept = hoursSlept
        entry.sleepQuality = Int16(sleepQuality)
        entry.racingThoughts = racingThoughts
        entry.weirdDreams = weirdDreams

        // Stress & Anxiety
        entry.stressTriggers = stressTriggers
        entry.morningAnxiety = Int16(morningAnxiety)
        entry.afternoonAnxiety = Int16(afternoonAnxiety)
        entry.eveningAnxiety = Int16(eveningAnxiety)
        entry.physicalSymptoms = physicalSymptoms

        // Focus & Functioning
        entry.brainFog = Int16(brainFog)
        entry.forgetfulness = Int16(forgetfulness)
        entry.forgetfulnessExamples = forgetfulnessExamples

        // Fitness & Activity
        entry.physicallyActive = physicallyActive
        entry.activityType = activityType
        entry.activityDuration = activityDuration

        // Nutrition
        entry.mealsCount = Int16(mealsCount)
        entry.foodQuality = foodQuality.rawValue

        // General
        entry.overallMood = overallMood
        entry.otherNotes = otherNotes

        do {
            try viewContext.save()
            existingEntry = entry
            isEditing = true
        } catch {
            print("Error saving entry: \(error)")
        }
    }

    // MARK: - Medication Helpers

    func medicationLog(for medication: Medication) -> Binding<MedicationLogState> {
        Binding(
            get: {
                self.medicationLogs[medication.id!] ?? MedicationLogState(
                    status: .pending,
                    dosage: medication.formattedDosage,
                    timeTaken: nil,
                    notes: ""
                )
            },
            set: { newValue in
                self.medicationLogs[medication.id!] = newValue
            }
        )
    }
}

// MARK: - Medication Log State

struct MedicationLogState {
    var status: MedicationStatus
    var dosage: String
    var timeTaken: Date?
    var notes: String

    var isTaken: Bool {
        get { status == .taken }
        set { status = newValue ? .taken : .pending }
    }
}

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

    // Medications
    @Published var concertaTaken: Bool = false
    @Published var concertaDose: Double = UserDefaults.standard.lastConcertaDose
    @Published var concertaTime: Date = Date()
    @Published var estradiolApplied: Bool = false
    @Published var estradiolDosage: String = UserDefaults.standard.lastEstradiolDosage
    @Published var nortryptilineTaken: Bool = false
    @Published var nortryptilineDose: Double = UserDefaults.standard.lastNortryptilineDose

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
        loadTodayEntry()
    }

    var dayOfWeek: String {
        date.formatted(.dateTime.weekday(.wide))
    }

    var formattedDate: String {
        date.formatted(date: .long, time: .omitted)
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
        concertaTaken = entry.concertaTaken
        concertaDose = entry.concertaDose
        concertaTime = entry.concertaTime ?? Date()
        estradiolApplied = entry.estradiolApplied
        estradiolDosage = entry.estradiolDosage ?? ""
        nortryptilineTaken = entry.nortryptilineTaken
        nortryptilineDose = entry.nortryptilineDose

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
        concertaTaken = false
        concertaDose = UserDefaults.standard.lastConcertaDose
        concertaTime = Date()
        estradiolApplied = false
        estradiolDosage = UserDefaults.standard.lastEstradiolDosage
        nortryptilineTaken = false
        nortryptilineDose = UserDefaults.standard.lastNortryptilineDose

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

        // Medications
        entry.concertaTaken = concertaTaken
        entry.concertaDose = concertaDose
        entry.concertaTime = concertaTaken ? concertaTime : nil
        entry.estradiolApplied = estradiolApplied
        entry.estradiolDosage = estradiolDosage
        entry.nortryptilineTaken = nortryptilineTaken
        entry.nortryptilineDose = nortryptilineDose

        // Save last used doses for smart defaults
        if concertaTaken {
            UserDefaults.standard.lastConcertaDose = concertaDose
        }
        if !estradiolDosage.isEmpty {
            UserDefaults.standard.lastEstradiolDosage = estradiolDosage
        }
        if nortryptilineTaken {
            UserDefaults.standard.lastNortryptilineDose = nortryptilineDose
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
}

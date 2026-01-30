import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for previews
        for i in 0..<7 {
            let entry = DailyEntry(context: viewContext)
            entry.id = UUID()
            entry.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
            entry.dayOfWeek = entry.date?.formatted(.dateTime.weekday(.wide))
            entry.concertaTaken = Bool.random()
            entry.concertaDose = 36
            entry.estradiolApplied = i % 3 == 0
            entry.nortryptilineTaken = true
            entry.nortryptilineDose = 25
            entry.hoursSlept = Double.random(in: 5...9)
            entry.sleepQuality = Int16.random(in: 1...5)
            entry.racingThoughts = Bool.random()
            entry.weirdDreams = Bool.random()
            entry.morningAnxiety = Int16.random(in: 0...10)
            entry.afternoonAnxiety = Int16.random(in: 0...10)
            entry.eveningAnxiety = Int16.random(in: 0...10)
            entry.brainFog = Int16.random(in: 0...5)
            entry.forgetfulness = Int16.random(in: 0...5)
            entry.physicallyActive = Bool.random()
            entry.mealsCount = Int16.random(in: 1...4)
            entry.foodQuality = ["OK", "Good", "Not So Good", "Bad"].randomElement()
            entry.overallMood = ["Good", "Okay", "Tired", "Anxious", "Productive"].randomElement()
        }

        // Sample dream log
        let dream = DreamLog(context: viewContext)
        dream.id = UUID()
        dream.date = Date()
        dream.dreamDescription = "Sample dream description"
        dream.possibleTriggers = "Late night snack, stress from work"

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Thrival")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

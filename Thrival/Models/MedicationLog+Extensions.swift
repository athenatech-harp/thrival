import Foundation
import CoreData

enum MedicationStatus: String, CaseIterable {
    case taken = "Taken"
    case skipped = "Skipped"
    case notApplicable = "N/A"
    case pending = "Pending"

    var icon: String {
        switch self {
        case .taken: return "checkmark.circle.fill"
        case .skipped: return "xmark.circle.fill"
        case .notApplicable: return "minus.circle.fill"
        case .pending: return "circle"
        }
    }

    var color: String {
        switch self {
        case .taken: return "green"
        case .skipped: return "red"
        case .notApplicable: return "gray"
        case .pending: return "secondary"
        }
    }
}

extension MedicationLog {
    var status: MedicationStatus {
        get {
            if taken { return .taken }
            if skipped { return .skipped }
            if notApplicable { return .notApplicable }
            return .pending
        }
        set {
            taken = false
            skipped = false
            notApplicable = false

            switch newValue {
            case .taken:
                taken = true
            case .skipped:
                skipped = true
            case .notApplicable:
                notApplicable = true
            case .pending:
                break
            }
        }
    }

    var formattedTime: String? {
        guard let time = timeTaken else { return nil }
        return time.formatted(date: .omitted, time: .shortened)
    }

    var medicationName: String {
        medication?.name ?? "Unknown"
    }

    static func create(
        in context: NSManagedObjectContext,
        medication: Medication,
        dailyEntry: DailyEntry
    ) -> MedicationLog {
        let log = MedicationLog(context: context)
        log.id = UUID()
        log.medication = medication
        log.dailyEntry = dailyEntry
        log.taken = false
        log.skipped = false
        log.notApplicable = false
        log.dosage = medication.formattedDosage
        return log
    }

    static func findOrCreate(
        in context: NSManagedObjectContext,
        medication: Medication,
        dailyEntry: DailyEntry
    ) -> MedicationLog {
        let request = NSFetchRequest<MedicationLog>(entityName: "MedicationLog")
        request.predicate = NSPredicate(
            format: "medication == %@ AND dailyEntry == %@",
            medication, dailyEntry
        )
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        return create(in: context, medication: medication, dailyEntry: dailyEntry)
    }
}

import Foundation
import CoreData

enum MedicationFrequency: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case twiceDaily = "Twice Daily"
    case twiceWeekly = "Twice Weekly"
    case weekly = "Weekly"
    case asNeeded = "As Needed"
    case other = "Other"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .daily: return "Daily"
        case .twiceDaily: return "2x/day"
        case .twiceWeekly: return "2x/week"
        case .weekly: return "Weekly"
        case .asNeeded: return "PRN"
        case .other: return "Other"
        }
    }

    var requiresDailyTracking: Bool {
        switch self {
        case .daily, .twiceDaily, .asNeeded:
            return true
        case .twiceWeekly, .weekly, .other:
            return false
        }
    }
}

extension Medication {
    var frequencyEnum: MedicationFrequency {
        get {
            MedicationFrequency(rawValue: frequency ?? "Daily") ?? .daily
        }
        set {
            frequency = newValue.rawValue
        }
    }

    var formattedDosage: String {
        guard let dosage = defaultDosage, !dosage.isEmpty else { return "" }
        let unit = dosageUnit ?? ""
        return "\(dosage)\(unit.isEmpty ? "" : " \(unit)")"
    }

    static func fetchRequest(activeOnly: Bool = true) -> NSFetchRequest<Medication> {
        let request = NSFetchRequest<Medication>(entityName: "Medication")
        if activeOnly {
            request.predicate = NSPredicate(format: "isActive == YES")
        }
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Medication.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Medication.name, ascending: true)
        ]
        return request
    }

    static func create(
        in context: NSManagedObjectContext,
        name: String,
        defaultDosage: String? = nil,
        dosageUnit: String? = nil,
        frequency: MedicationFrequency = .daily,
        notes: String? = nil
    ) -> Medication {
        let medication = Medication(context: context)
        medication.id = UUID()
        medication.name = name
        medication.defaultDosage = defaultDosage
        medication.dosageUnit = dosageUnit
        medication.frequency = frequency.rawValue
        medication.notes = notes
        medication.isActive = true
        medication.createdAt = Date()
        medication.sortOrder = 0
        return medication
    }
}

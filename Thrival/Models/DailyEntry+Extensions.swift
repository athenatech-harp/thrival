import Foundation
import CoreData

extension DailyEntry {
    var formattedDate: String {
        date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
    }

    var formattedDayOfWeek: String {
        date?.formatted(.dateTime.weekday(.wide)) ?? ""
    }

    var averageAnxiety: Double {
        let total = Double(morningAnxiety + afternoonAnxiety + eveningAnxiety)
        return total / 3.0
    }

    var sleepQualityDescription: String {
        switch sleepQuality {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Excellent"
        default: return "Unknown"
        }
    }

    var brainFogDescription: String {
        switch brainFog {
        case 0: return "None"
        case 1: return "Minimal"
        case 2: return "Mild"
        case 3: return "Moderate"
        case 4: return "Significant"
        case 5: return "Severe"
        default: return "Unknown"
        }
    }

    var forgetfulnessDescription: String {
        switch forgetfulness {
        case 0: return "None"
        case 1: return "Minimal"
        case 2: return "Mild"
        case 3: return "Moderate"
        case 4: return "Significant"
        case 5: return "Severe"
        default: return "Unknown"
        }
    }

    static func fetchRequest(for date: Date) -> NSFetchRequest<DailyEntry> {
        let request = DailyEntry.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        return request
    }

    static func recentEntriesFetchRequest(limit: Int = 30) -> NSFetchRequest<DailyEntry> {
        let request = DailyEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: false)]
        request.fetchLimit = limit
        return request
    }
}

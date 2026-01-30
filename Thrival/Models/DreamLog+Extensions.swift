import Foundation
import CoreData

extension DreamLog {
    var formattedDate: String {
        date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
    }

    static func recentDreamsFetchRequest(limit: Int = 50) -> NSFetchRequest<DreamLog> {
        let request = DreamLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DreamLog.date, ascending: false)]
        request.fetchLimit = limit
        return request
    }
}

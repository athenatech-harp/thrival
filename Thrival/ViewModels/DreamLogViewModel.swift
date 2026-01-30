import Foundation
import CoreData
import SwiftUI

@MainActor
class DreamLogViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext

    @Published var date: Date = Date()
    @Published var dreamDescription: String = ""
    @Published var possibleTriggers: String = ""

    private var editingDream: DreamLog?

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    var isValid: Bool {
        !dreamDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadDream(_ dream: DreamLog) {
        editingDream = dream
        date = dream.date ?? Date()
        dreamDescription = dream.dreamDescription ?? ""
        possibleTriggers = dream.possibleTriggers ?? ""
    }

    func save() {
        let dream = editingDream ?? DreamLog(context: viewContext)

        if editingDream == nil {
            dream.id = UUID()
        }

        dream.date = date
        dream.dreamDescription = dreamDescription
        dream.possibleTriggers = possibleTriggers

        do {
            try viewContext.save()
            reset()
        } catch {
            print("Error saving dream: \(error)")
        }
    }

    func delete(_ dream: DreamLog) {
        viewContext.delete(dream)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting dream: \(error)")
        }
    }

    func reset() {
        editingDream = nil
        date = Date()
        dreamDescription = ""
        possibleTriggers = ""
    }
}

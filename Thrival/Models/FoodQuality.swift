import Foundation

enum FoodQuality: String, CaseIterable, Identifiable {
    case good = "Good"
    case ok = "OK"
    case notSoGood = "Not So Good"
    case bad = "Bad"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .good: return "😊"
        case .ok: return "😐"
        case .notSoGood: return "😕"
        case .bad: return "😞"
        }
    }
}

import Foundation

extension UserDefaults {
    private enum Keys {
        static let lastConcertaDose = "lastConcertaDose"
        static let lastEstradiolDosage = "lastEstradiolDosage"
        static let lastNortryptilineDose = "lastNortryptilineDose"
    }

    var lastConcertaDose: Double {
        get {
            let value = double(forKey: Keys.lastConcertaDose)
            return value > 0 ? value : 36.0 // Default dose
        }
        set {
            set(newValue, forKey: Keys.lastConcertaDose)
        }
    }

    var lastEstradiolDosage: String {
        get {
            string(forKey: Keys.lastEstradiolDosage) ?? ""
        }
        set {
            set(newValue, forKey: Keys.lastEstradiolDosage)
        }
    }

    var lastNortryptilineDose: Double {
        get {
            let value = double(forKey: Keys.lastNortryptilineDose)
            return value > 0 ? value : 25.0 // Default dose
        }
        set {
            set(newValue, forKey: Keys.lastNortryptilineDose)
        }
    }
}

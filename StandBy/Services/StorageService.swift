import Foundation

protocol StorageProviding: Sendable {
    func loadSettings() -> Settings
    func saveSettings(_ settings: Settings)
    func loadDailyRecord(for day: CalendarDay) -> DailyRecord
    func saveDailyRecord(_ record: DailyRecord)
    func nextStretchIndex() -> Int
    func advanceStretchIndex(count: Int)
}

final class UserDefaultsStorageProvider: StorageProviding, Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSettings() -> Settings {
        let decoder = JSONDecoder()
        guard let data = defaults.data(forKey: "settings"),
              let settings = try? decoder.decode(Settings.self, from: data)
        else {
            return Settings()
        }
        return settings
    }

    func saveSettings(_ settings: Settings) {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: "settings")
        } catch {
            assertionFailure("Failed to encode settings: \(error)")
        }
    }

    func loadDailyRecord(for day: CalendarDay) -> DailyRecord {
        let decoder = JSONDecoder()
        let key = dailyRecordKey(for: day)
        guard let data = defaults.data(forKey: key),
              let record = try? decoder.decode(DailyRecord.self, from: data)
        else {
            return DailyRecord(date: day)
        }
        return record
    }

    func saveDailyRecord(_ record: DailyRecord) {
        do {
            let data = try JSONEncoder().encode(record)
            defaults.set(data, forKey: dailyRecordKey(for: record.date))
        } catch {
            assertionFailure("Failed to encode daily record: \(error)")
        }
    }

    func nextStretchIndex() -> Int {
        defaults.integer(forKey: "lastStretchIndex")
    }

    func advanceStretchIndex(count: Int) {
        guard count > 0 else { return }
        let current = defaults.integer(forKey: "lastStretchIndex")
        defaults.set((current + 1) % count, forKey: "lastStretchIndex")
    }

    private func dailyRecordKey(for day: CalendarDay) -> String {
        "dailyRecord_\(day.value)"
    }
}

import Foundation

nonisolated struct Settings: Codable, Equatable, Sendable {
    static let stretchIntervalRange = 5...120
    static let idleThresholdRange = 1...30

    var stretchIntervalMinutes: Int = 30 {
        didSet {
            stretchIntervalMinutes = min(max(stretchIntervalMinutes, Self.stretchIntervalRange.lowerBound), Self.stretchIntervalRange.upperBound)
        }
    }

    var idleThresholdMinutes: Int = 5 {
        didSet {
            idleThresholdMinutes = min(max(idleThresholdMinutes, Self.idleThresholdRange.lowerBound), Self.idleThresholdRange.upperBound)
        }
    }
    var launchAtLogin: Bool = false

    init(stretchIntervalMinutes: Int = 30, idleThresholdMinutes: Int = 5, launchAtLogin: Bool = false) {
        self.stretchIntervalMinutes = min(max(stretchIntervalMinutes, Self.stretchIntervalRange.lowerBound), Self.stretchIntervalRange.upperBound)
        self.idleThresholdMinutes = min(max(idleThresholdMinutes, Self.idleThresholdRange.lowerBound), Self.idleThresholdRange.upperBound)
        self.launchAtLogin = launchAtLogin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            stretchIntervalMinutes: try container.decode(Int.self, forKey: .stretchIntervalMinutes),
            idleThresholdMinutes: try container.decode(Int.self, forKey: .idleThresholdMinutes),
            launchAtLogin: try container.decode(Bool.self, forKey: .launchAtLogin)
        )
    }
}

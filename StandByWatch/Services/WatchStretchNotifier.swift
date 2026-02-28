import UserNotifications
import WatchKit

protocol HapticPlaying: Sendable {
    func play(_ type: WKHapticType)
}

/// @unchecked Sendable: WKInterfaceDevice.current() is a shared singleton; play(_:) is thread-safe.
extension WKInterfaceDevice: @retroactive @unchecked Sendable {}
extension WKInterfaceDevice: HapticPlaying {}

struct WatchStretchNotifier {
    private let storage: any StorageProviding
    private let sender: any NotificationSending
    private let haptic: any HapticPlaying

    init(
        storage: any StorageProviding,
        sender: any NotificationSending = UNNotificationSender(),
        haptic: any HapticPlaying = WKInterfaceDevice.current()
    ) {
        self.storage = storage
        self.sender = sender
        self.haptic = haptic
    }

    func requestPermission() async -> Bool {
        await sender.requestAuthorization()
    }

    func sendStretchReminder(stretches: [Stretch], hapticEnabled: Bool) {
        guard !stretches.isEmpty else { return }

        // NOTE: Rotation logic mirrors StretchNotifier (macOS). Kept inline for simplicity.
        let index = storage.nextStretchIndex()
        let stretch = stretches[index % stretches.count]
        storage.advanceStretchIndex(count: stretches.count)

        sender.send(
            title: String(localized: "Time to stretch!"),
            body: String(localized: "\(stretch.name) (\(stretch.durationSeconds)s) — \(stretch.instruction)")
        )

        if hapticEnabled {
            haptic.play(.notification)
        }
    }
}

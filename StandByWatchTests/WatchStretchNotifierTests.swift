import Foundation
import Testing
import WatchKit

@testable import StandByWatch

private final class SpyNotificationSender: NotificationSending, @unchecked Sendable {
    var authorizationResult = true
    var sentNotifications: [(title: String, body: String)] = []

    func requestAuthorization() async -> Bool {
        authorizationResult
    }

    func send(title: String, body: String) {
        sentNotifications.append((title: title, body: body))
    }
}

private final class SpyHapticPlayer: HapticPlaying, @unchecked Sendable {
    var playedTypes: [WKHapticType] = []

    func play(_ type: WKHapticType) {
        playedTypes.append(type)
    }
}

private func makeStretches() -> [Stretch] {
    [
        Stretch(id: "a", name: "ストレッチA", instruction: "説明A", durationSeconds: 30, targetArea: "腰"),
        Stretch(id: "b", name: "ストレッチB", instruction: "説明B", durationSeconds: 20, targetArea: "肩"),
    ]
}

struct WatchStretchNotifierTests {
    private func makeSUT() -> (WatchStretchNotifier, SpyNotificationSender, SpyHapticPlayer) {
        let suite = "com.mickamy.StandBy.tests.\(UUID().uuidString)"
        let storage = UserDefaultsStorageProvider(defaults: UserDefaults(suiteName: suite)!)
        let sender = SpyNotificationSender()
        let haptic = SpyHapticPlayer()
        let notifier = WatchStretchNotifier(storage: storage, sender: sender, haptic: haptic)
        return (notifier, sender, haptic)
    }

    @Test func requestPermissionReturnsGranted() async {
        let (sut, sender, _) = makeSUT()
        sender.authorizationResult = true
        #expect(await sut.requestPermission() == true)
    }

    @Test func requestPermissionReturnsDenied() async {
        let (sut, sender, _) = makeSUT()
        sender.authorizationResult = false
        #expect(await sut.requestPermission() == false)
    }

    @Test func sendStretchReminderDoesNothingWhenEmpty() {
        let (sut, sender, haptic) = makeSUT()
        sut.sendStretchReminder(stretches: [], hapticEnabled: true)
        #expect(sender.sentNotifications.isEmpty)
        #expect(haptic.playedTypes.isEmpty)
    }

    @Test func sendStretchReminderSendsNotification() {
        let (sut, sender, _) = makeSUT()
        sut.sendStretchReminder(stretches: makeStretches(), hapticEnabled: true)
        #expect(sender.sentNotifications.count == 1)
    }

    @Test func sendStretchReminderRotatesThroughStretches() {
        let (sut, sender, _) = makeSUT()
        let stretches = makeStretches()

        sut.sendStretchReminder(stretches: stretches, hapticEnabled: false)
        sut.sendStretchReminder(stretches: stretches, hapticEnabled: false)
        sut.sendStretchReminder(stretches: stretches, hapticEnabled: false)

        #expect(sender.sentNotifications.count == 3)
        #expect(sender.sentNotifications[0].body.contains("ストレッチA"))
        #expect(sender.sentNotifications[1].body.contains("ストレッチB"))
        #expect(sender.sentNotifications[2].body.contains("ストレッチA"))
    }

    @Test func playsHapticWhenEnabled() {
        let (sut, _, haptic) = makeSUT()
        sut.sendStretchReminder(stretches: makeStretches(), hapticEnabled: true)
        #expect(haptic.playedTypes == [.notification])
    }

    @Test func skipsHapticWhenDisabled() {
        let (sut, _, haptic) = makeSUT()
        sut.sendStretchReminder(stretches: makeStretches(), hapticEnabled: false)
        #expect(haptic.playedTypes.isEmpty)
    }
}

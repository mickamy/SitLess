import Foundation
import Testing

@testable import SitLess

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

private func makeStretches() -> [Stretch] {
    [
        Stretch(id: "a", name: "ストレッチA", instruction: "説明A", durationSeconds: 30, targetArea: "腰"),
        Stretch(id: "b", name: "ストレッチB", instruction: "説明B", durationSeconds: 20, targetArea: "肩"),
    ]
}

struct StretchNotifierTests {
    private func makeSUT() -> (StretchNotifier, SpyNotificationSender) {
        let suite = "com.mickamy.SitLess.tests.\(UUID().uuidString)"
        let storage = UserDefaultsStorageProvider(defaults: UserDefaults(suiteName: suite)!)
        let sender = SpyNotificationSender()
        let notifier = StretchNotifier(storage: storage, sender: sender)
        return (notifier, sender)
    }

    @Test func requestPermissionReturnsGranted() async {
        let (sut, sender) = makeSUT()
        sender.authorizationResult = true
        let result = await sut.requestPermission()
        #expect(result == true)
    }

    @Test func requestPermissionReturnsDenied() async {
        let (sut, sender) = makeSUT()
        sender.authorizationResult = false
        let result = await sut.requestPermission()
        #expect(result == false)
    }

    @Test func sendStretchReminderDoesNothingWhenEmpty() {
        let (sut, sender) = makeSUT()
        sut.sendStretchReminder(stretches: [])
        #expect(sender.sentNotifications.isEmpty)
    }

    @Test func sendStretchReminderSendsNotification() {
        let (sut, sender) = makeSUT()
        sut.sendStretchReminder(stretches: makeStretches())

        #expect(sender.sentNotifications.count == 1)
        #expect(sender.sentNotifications[0].title == "ストレッチの時間です！")
        #expect(sender.sentNotifications[0].body.contains("ストレッチA"))
    }

    @Test func sendStretchReminderRotatesThroughStretches() {
        let (sut, sender) = makeSUT()
        let stretches = makeStretches()

        sut.sendStretchReminder(stretches: stretches)
        sut.sendStretchReminder(stretches: stretches)
        sut.sendStretchReminder(stretches: stretches)

        #expect(sender.sentNotifications.count == 3)
        #expect(sender.sentNotifications[0].body.contains("ストレッチA"))
        #expect(sender.sentNotifications[1].body.contains("ストレッチB"))
        #expect(sender.sentNotifications[2].body.contains("ストレッチA"))
    }

    @Test func notificationBodyIncludesDurationAndInstruction() {
        let (sut, sender) = makeSUT()
        let stretches = makeStretches()

        sut.sendStretchReminder(stretches: stretches)

        let body = sender.sentNotifications[0].body
        #expect(body.contains("30秒"))
        #expect(body.contains("説明A"))
    }
}

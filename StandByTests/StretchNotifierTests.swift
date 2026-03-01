import Foundation
import Testing

@testable import StandBy

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
        Stretch(id: "a", name: "Stretch A", instruction: "Instruction A", durationSeconds: 30, targetArea: "Lower Back"),
        Stretch(id: "b", name: "Stretch B", instruction: "Instruction B", durationSeconds: 20, targetArea: "Shoulders"),
    ]
}

struct StretchNotifierTests {
    private func makeSUT() -> (StretchNotifier, SpyNotificationSender) {
        let suite = "com.mickamy.StandBy.tests.\(UUID().uuidString)"
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
        #expect(sender.sentNotifications[0].title == "Time to stretch!")
        #expect(sender.sentNotifications[0].body.contains("Stretch A"))
    }

    @Test func sendStretchReminderRotatesThroughStretches() {
        let (sut, sender) = makeSUT()
        let stretches = makeStretches()

        sut.sendStretchReminder(stretches: stretches)
        sut.sendStretchReminder(stretches: stretches)
        sut.sendStretchReminder(stretches: stretches)

        #expect(sender.sentNotifications.count == 3)
        #expect(sender.sentNotifications[0].body.contains("Stretch A"))
        #expect(sender.sentNotifications[1].body.contains("Stretch B"))
        #expect(sender.sentNotifications[2].body.contains("Stretch A"))
    }

    @Test func notificationBodyIncludesDurationAndInstruction() {
        let (sut, sender) = makeSUT()
        let stretches = makeStretches()

        sut.sendStretchReminder(stretches: stretches)

        let body = sender.sentNotifications[0].body
        #expect(body.contains("30s"))
        #expect(body.contains("Instruction A"))
    }
}

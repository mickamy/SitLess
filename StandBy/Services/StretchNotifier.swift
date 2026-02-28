import Foundation

struct StretchNotifier {
    private let storage: any StorageProviding
    private let sender: any NotificationSending

    init(storage: any StorageProviding, sender: any NotificationSending = UNNotificationSender()) {
        self.storage = storage
        self.sender = sender
    }

    func requestPermission() async -> Bool {
        await sender.requestAuthorization()
    }

    func sendStretchReminder(stretches: [Stretch]) {
        guard !stretches.isEmpty else { return }

        let index = storage.nextStretchIndex()
        let stretch = stretches[index % stretches.count]
        storage.advanceStretchIndex(count: stretches.count)

        sender.send(
            title: "ストレッチの時間です！",
            body: "\(stretch.name)（\(stretch.durationSeconds)秒）— \(stretch.instruction)"
        )
    }
}

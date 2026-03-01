import CoreMotion
import Foundation

protocol MotionActivityProviding: Sendable {
    func startMonitoring(handler: @escaping @Sendable (Bool) -> Void)
    func stopMonitoring()
    func queryStationaryDuration(from start: Date, to end: Date) async -> TimeInterval
}

/// @unchecked Sendable: CMMotionActivityManager is thread-safe; serial queue serializes all callbacks.
final class CMMotionActivityProvider: MotionActivityProviding, @unchecked Sendable {
    private let manager = CMMotionActivityManager()
    private let queue: OperationQueue

    init() {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInitiated
        self.queue = q
    }

    func startMonitoring(handler: @escaping @Sendable (Bool) -> Void) {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        manager.startActivityUpdates(to: queue) { activity in
            guard let activity else { return }
            let isActive = activity.walking || activity.running
                || activity.cycling || activity.automotive
            if isActive {
                handler(false)
            } else if activity.stationary {
                handler(true)
            } else if activity.confidence != .low {
                // Unknown activity with medium/high confidence and no active
                // movement detected — likely sitting. Low-confidence updates
                // are ignored to keep the previous state.
                handler(true)
            }
        }
    }

    func stopMonitoring() {
        manager.stopActivityUpdates()
    }

    func queryStationaryDuration(from start: Date, to end: Date) async -> TimeInterval {
        guard CMMotionActivityManager.isActivityAvailable() else { return 0 }

        return await withCheckedContinuation { continuation in
            manager.queryActivityStarting(from: start, to: end, to: queue) { activities, error in
                guard let activities, error == nil else {
                    continuation.resume(returning: 0)
                    return
                }

                var total: TimeInterval = 0
                for (i, activity) in activities.enumerated() {
                    let isActive = activity.walking || activity.running
                        || activity.cycling || activity.automotive
                    let isSitting = activity.stationary
                        || (!isActive && activity.confidence != .low)
                    guard isSitting else { continue }
                    let nextStart = i + 1 < activities.count ? activities[i + 1].startDate : end
                    total += nextStart.timeIntervalSince(activity.startDate)
                }
                continuation.resume(returning: total)
            }
        }
    }
}

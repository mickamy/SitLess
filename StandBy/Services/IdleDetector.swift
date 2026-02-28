import Foundation
import IOKit

protocol IdleTimeProviding: Sendable {
    func systemIdleTime() -> TimeInterval?
}

struct IOKitIdleTimeProvider: IdleTimeProviding {
    /// Returns the system idle time in seconds, or nil if unavailable.
    /// Reads HIDIdleTime from IOHIDSystem via IOKit registry.
    func systemIdleTime() -> TimeInterval? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem"),
            &iterator
        ) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }

        let entry = IOIteratorNext(iterator)
        guard entry != 0 else { return nil }
        defer { IOObjectRelease(entry) }

        var dict: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(
            entry, &dict, kCFAllocatorDefault, 0
        ) == KERN_SUCCESS,
              let d = dict?.takeRetainedValue() as? [String: Any],
              let nanos = d["HIDIdleTime"] as? Int64
        else { return nil }

        return Double(nanos) / Double(NSEC_PER_SEC)
    }
}

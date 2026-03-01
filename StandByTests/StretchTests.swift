import Foundation
import Testing

@testable import StandBy

struct StretchTests {
    @Test func codableRoundTrip() throws {
        let stretch = Stretch(
            id: "cat-cow",
            name: "Cat & Cow",
            instruction: "On all fours, round then arch your back",
            durationSeconds: 30,
            targetArea: "Lower Back"
        )

        let data = try JSONEncoder().encode(stretch)
        let decoded = try JSONDecoder().decode(Stretch.self, from: data)

        #expect(decoded == stretch)
    }

    @Test func equatableUsesAllProperties() {
        let a = Stretch(id: "cat-cow", name: "A", instruction: "", durationSeconds: 30, targetArea: "Lower Back")
        let b = Stretch(id: "cat-cow", name: "B", instruction: "", durationSeconds: 60, targetArea: "Shoulders")

        #expect(a.id == b.id)
        #expect(a != b)
    }

    @Test func decodesFromJSON() throws {
        let json = """
        {
            "id": "child-pose",
            "name": "Child's Pose",
            "instruction": "From kneeling, reach your arms forward",
            "durationSeconds": 30,
            "targetArea": "Lower Back"
        }
        """
        let decoded = try JSONDecoder().decode(Stretch.self, from: Data(json.utf8))

        #expect(decoded.id == "child-pose")
        #expect(decoded.name == "Child's Pose")
        #expect(decoded.durationSeconds == 30)
    }
}

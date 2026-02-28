import Foundation
import Testing

@testable import StandBy

struct StretchTests {
    @Test func codableRoundTrip() throws {
        let stretch = Stretch(
            id: "cat-cow",
            name: "キャット&カウ",
            instruction: "四つん這いで背中を丸める→反らす",
            durationSeconds: 30,
            targetArea: "腰"
        )

        let data = try JSONEncoder().encode(stretch)
        let decoded = try JSONDecoder().decode(Stretch.self, from: data)

        #expect(decoded == stretch)
    }

    @Test func equatableUsesAllProperties() {
        let a = Stretch(id: "cat-cow", name: "A", instruction: "", durationSeconds: 30, targetArea: "腰")
        let b = Stretch(id: "cat-cow", name: "B", instruction: "", durationSeconds: 60, targetArea: "肩")

        #expect(a.id == b.id)
        #expect(a != b)
    }

    @Test func decodesFromJSON() throws {
        let json = """
        {
            "id": "child-pose",
            "name": "チャイルドポーズ",
            "instruction": "正座から前に手を伸ばす",
            "durationSeconds": 30,
            "targetArea": "腰"
        }
        """
        let decoded = try JSONDecoder().decode(Stretch.self, from: Data(json.utf8))

        #expect(decoded.id == "child-pose")
        #expect(decoded.name == "チャイルドポーズ")
        #expect(decoded.durationSeconds == 30)
    }
}

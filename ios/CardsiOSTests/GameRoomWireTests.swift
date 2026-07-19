import XCTest
@testable import CardsiOS

final class GameRoomWireTests: XCTestCase {
    func testBLEFramerReassemblesFragmentedAndCoalescedEnvelopes() {
        let first = Data("first-envelope".utf8)
        let second = Data(repeating: 0x42, count: 400)
        let packets = BLEPacketFramer.packets(for: first) + BLEPacketFramer.packets(for: second)
        var receiver = BLEPacketFramer()
        let decoded = packets.flatMap { receiver.append(packet: $0) }
        XCTAssertEqual(decoded, [first, second])
    }

    func testAlignmentOnlyAcceptsTheSharedMarkerContract() {
        let valid = SharedARAlignment(markerID: SharedARAlignment.markerID, markerWidthMetres: 0.16, revision: 3, position: [0, 0, 0], orientation: [0, 0, 0, 1])
        let invalid = SharedARAlignment(markerID: "other", markerWidthMetres: 0.16, revision: 3, position: [0, 0, 0], orientation: [0, 0, 0, 1])
        XCTAssertTrue(valid.isValid)
        XCTAssertFalse(invalid.isValid)
    }
}

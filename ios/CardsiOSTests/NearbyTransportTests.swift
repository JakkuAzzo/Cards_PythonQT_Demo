import XCTest
@testable import CardsiOS

@MainActor
final class NearbyTransportTests: XCTestCase {
    func testLoopbackDeliversBroadcastAndPrivateEnvelopes() {
        let bus = LoopbackNearbyBus()
        let host = LoopbackNearbyTransport(localPeerID: "host", bus: bus)
        let guestA = LoopbackNearbyTransport(localPeerID: "a", bus: bus)
        let guestB = LoopbackNearbyTransport(localPeerID: "b", bus: bus)
        var receivedByA: [NearbyEnvelope] = []
        var receivedByB: [NearbyEnvelope] = []
        guestA.onEnvelope = { receivedByA.append($0) }
        guestB.onEnvelope = { receivedByB.append($0) }

        host.host(sessionID: "room")
        guestA.join(sessionID: "room")
        guestB.join(sessionID: "room")
        host.send(envelope(recipientID: nil, messageID: "public"))
        host.send(envelope(recipientID: "a", messageID: "private"))

        XCTAssertEqual(receivedByA.map(\.messageID), ["public", "private"])
        XCTAssertEqual(receivedByB.map(\.messageID), ["public"])
    }

    private func envelope(recipientID: String?, messageID: String) -> NearbyEnvelope {
        NearbyEnvelope(
            protocolVersion: 1,
            sessionID: "room",
            messageID: messageID,
            senderID: "host",
            revision: 1,
            type: recipientID == nil ? .event : .privateEvent,
            recipientID: recipientID,
            payload: ["event": "card-drawn"]
        )
    }
}

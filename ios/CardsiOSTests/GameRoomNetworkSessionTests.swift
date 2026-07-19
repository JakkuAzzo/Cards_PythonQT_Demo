import XCTest
@testable import CardsiOS

@MainActor
final class GameRoomNetworkSessionTests: XCTestCase {
    func testGuestCommandReachesHostAndPrivateStateDoesNotLeak() {
        let bus = LoopbackNearbyBus()
        let hostTransport = LoopbackNearbyTransport(localPeerID: "host", bus: bus)
        let guestTransport = LoopbackNearbyTransport(localPeerID: "guest", bus: bus)
        let host = GameRoomNetworkSession(roomKind: .poker, localPlayerID: "host", localPlayerName: "Host", sessionCode: "CARDS-1234", role: .host, transport: hostTransport)
        let guest = GameRoomNetworkSession(roomKind: .poker, localPlayerID: "guest", localPlayerName: "Guest", sessionCode: "CARDS-1234", role: .guest, transport: guestTransport)
        var hostCommand: GameRoomCommand?
        var publicState: Data?
        var privateState: Data?
        host.onHostCommand = { hostCommand = $0; return true }
        guest.onPublicSnapshot = { publicState = $0 }
        guest.onPrivateState = { privateState = $0 }
        host.connect(); guest.connect()

        guest.submit(GameRoomCommand(action: "bet", playerID: "guest", characterID: nil, amount: 20))
        XCTAssertEqual(hostCommand, GameRoomCommand(action: "bet", playerID: "guest", characterID: nil, amount: 20))

        host.publish(publicState: Data("public".utf8), privateStates: ["guest": Data("K♥ K♣".utf8), "other": Data("secret".utf8)])
        XCTAssertEqual(publicState, Data("public".utf8))
        XCTAssertEqual(privateState, Data("K♥ K♣".utf8))
    }
}

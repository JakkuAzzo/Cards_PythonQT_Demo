import Foundation

struct NearbyEnvelope: Codable, Equatable {
    let protocolVersion: Int
    let sessionID: String
    let messageID: String
    let senderID: String
    let revision: Int
    let type: MessageType
    let recipientID: String?
    let payload: [String: String]

    enum MessageType: String, Codable {
        case hello, join, snapshot, command, event
        case privateEvent = "private-event"
        case ack, error, ping
    }
}

@MainActor
protocol NearbyTransport: AnyObject {
    var localPeerID: String { get }
    var onEnvelope: ((NearbyEnvelope) -> Void)? { get set }
    var onPeersChanged: (([String]) -> Void)? { get set }
    func host(sessionID: String)
    func join(sessionID: String)
    func send(_ envelope: NearbyEnvelope)
    func disconnect()
}

@MainActor
final class LoopbackNearbyBus {
    private var sessions: [String: [String: LoopbackNearbyTransport]] = [:]

    func connect(_ transport: LoopbackNearbyTransport, sessionID: String) {
        sessions[sessionID, default: [:]][transport.localPeerID] = transport
        publishPeers(sessionID: sessionID)
    }

    func disconnect(_ transport: LoopbackNearbyTransport, sessionID: String?) {
        guard let sessionID else { return }
        sessions[sessionID]?[transport.localPeerID] = nil
        publishPeers(sessionID: sessionID)
    }

    func send(_ envelope: NearbyEnvelope) {
        let recipients = sessions[envelope.sessionID]?.values.filter {
            $0.localPeerID != envelope.senderID &&
            (envelope.recipientID == nil || envelope.recipientID == $0.localPeerID)
        } ?? []
        recipients.forEach { $0.receive(envelope) }
    }

    private func publishPeers(sessionID: String) {
        guard let peers = sessions[sessionID] else { return }
        let ids = Array(peers.keys).sorted()
        peers.values.forEach { transport in
            transport.onPeersChanged?(ids.filter { $0 != transport.localPeerID })
        }
    }
}

@MainActor
final class LoopbackNearbyTransport: NearbyTransport {
    let localPeerID: String
    var onEnvelope: ((NearbyEnvelope) -> Void)?
    var onPeersChanged: (([String]) -> Void)?

    private let bus: LoopbackNearbyBus
    private var sessionID: String?

    init(localPeerID: String, bus: LoopbackNearbyBus) {
        self.localPeerID = localPeerID
        self.bus = bus
    }

    func host(sessionID: String) { connect(sessionID: sessionID) }
    func join(sessionID: String) { connect(sessionID: sessionID) }
    func send(_ envelope: NearbyEnvelope) { bus.send(envelope) }

    func disconnect() {
        bus.disconnect(self, sessionID: sessionID)
        sessionID = nil
    }

    fileprivate func receive(_ envelope: NearbyEnvelope) {
        onEnvelope?(envelope)
    }

    private func connect(sessionID: String) {
        disconnect()
        self.sessionID = sessionID
        bus.connect(self, sessionID: sessionID)
    }
}
